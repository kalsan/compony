module Compony
  module ModelMixin
    extend ActiveSupport::Concern

    included do
      class_attribute :fields, default: {}
      class_attribute :feasibility_preventions, default: {}
      class_attribute :owner_model_attr

      class_attribute :autodetect_feasibilities_completed, default: false
    end

    class_methods do
      # This hook updates all fields from a subclass, making sure that fields point to correct model classes even in STI
      # e.g. in Parent: field :foo, ... omitted in child -> child.fields[:foo] should point to Child and not Parent.
      def inherited(subclass)
        super
        subclass.fields = subclass.fields.transform_values { |f| f.class.new(f.name, subclass, **f.extra_attrs) }
      end

      # DSL method, defines a new field which will be translated and can be added to field groups
      # If multilang is true, a suffixed field is generated for every available locale, along with a non-suffixed virtual field (useful with gem "mobility")
      def field(name, type, multilang: false, **extra_attrs)
        if multilang
          field(name, type, virtual: true, **extra_attrs)
          I18n.available_locales.each { |locale| field("#{name}_#{locale}", type, **extra_attrs) }
        else
          name = name.to_sym
          self.fields = fields.dup
          field = Compony.model_field_class_for(type.to_s.camelize).new(name, self, **extra_attrs)
          # Handle the case where ActiveType would interfere with attribute registration
          if defined?(ActiveType) && self <= ActiveType::Object && !include?(ActiveModel::Attributes)
            fail "Please add `include ActiveModel::Attributes` at the top of the class #{self}, as attributes cannot be registered otherwise with ActiveType."
          end
          # Register the field as an attribute
          if defined?(ActiveType) && self <= ActiveType::Object
            ar_attribute(name)
          else
            attribute(name)
          end
          fields[name] = field
        end
      end

      # DSL method, sets the containing model.
      # Use this when a model only makes sense within the context of another model and typically has no own index page.
      # For instance, a model LineItem that belongs_to :invoice would typically be owned_by :invoice.
      # Compony will automatically adjust Redirects and top actions.
      def owned_by(attribute_name)
        self.owner_model_attr = attribute_name.to_sym
      end

      # DSL method, part of the Feasibility feature
      # Block must return `false` if the action should be prevented.
      # @param assoc [ActiveRecord::Reflection] Internal, set by {autodetect_feasibilities!}. Allows {precompute_feasibility} to batch the check.
      def prevent(action_names, message, assoc: nil, &block)
        action_names = [action_names] unless action_names.is_a? Enumerable
        action_names.each do |action_name|
          self.feasibility_preventions = feasibility_preventions.dup # Prevent cross-class contamination
          feasibility_preventions[action_name.to_sym] ||= []
          feasibility_preventions[action_name.to_sym] << MethodAccessibleHash.new(action_name:, message:, assoc:, block:)
        end
      end

      # DSL method, part of the Feasibility feature
      # Skips autodetection of feasibilities
      def skip_autodetect_feasibilities
        self.autodetect_feasibilities_completed = true
      end

      def autodetect_feasibilities!
        return if autodetect_feasibilities_completed
        # Add a prevention that reflects the `has_many` `dependent' properties. Avoids that users can press buttons that will result in a failed destroy.
        reflect_on_all_associations.select { |assoc| %i[restrict_with_exception restrict_with_error].include? assoc.options[:dependent] }.each do |assoc|
          # The `assoc:` is stored so that `precompute_feasibility` can resolve dependent existence for a whole collection in a single query per
          # association (see batchable_feasibility_assoc?). When called on a single record (no precompute), the block below is used instead.
          prevent(:destroy, I18n.t('compony.feasibility.has_dependent_models', dependent_class: assoc.klass.model_name.human(count: 2)), assoc:) do
            if assoc.is_a? ActiveRecord::Reflection::HasOneReflection
              !public_send(assoc.name).nil?
            else
              public_send(assoc.name).any?
            end
          end
        end
        self.autodetect_feasibilities_completed = true
      end

      # Precomputes and caches feasibility for an entire collection of records, avoiding the N+1 queries that arise when `feasible?` is called per
      # record (e.g. when rendering destroy buttons for every row of an index). For every autodetected dependent-association prevention that can be
      # batched (see {batchable_feasibility_assoc?}), this issues a single existence query across all records instead of one query per record.
      # Preventions that cannot be batched (custom `prevent` blocks, polymorphic/through/STI-ambiguous or argument-taking-scope associations) fall
      # back to the per-record block. After this call, `feasible?` / `feasibility_messages` for the given action return cached results with no further
      # queries for the batched preventions.
      # @param records [Enumerable] the records to precompute feasibility for, typically the current index page
      # @param action_name [Symbol,String] the action to precompute, e.g. :destroy
      def precompute_feasibility(records, action_name)
        action_name = action_name.to_sym
        records = records.to_a
        return if records.empty?
        autodetect_feasibilities!
        # Seed the per-record message cache so feasible? treats these as already computed.
        records.each do |record|
          messages = record.instance_variable_get(:@feasibility_messages) || record.instance_variable_set(:@feasibility_messages, {})
          messages[action_name] = []
        end
        Array(feasibility_preventions[action_name]).each do |prevention|
          assoc = prevention[:assoc]
          if assoc && batchable_feasibility_assoc?(assoc)
            apply_batched_feasibility_prevention(records, action_name, prevention, assoc)
          else
            # Fallback: run the prevention block once per record (custom blocks, polymorphic/through/scoped associations).
            records.each do |record|
              record.instance_variable_get(:@feasibility_messages)[action_name] << prevention.message if record.instance_exec(&prevention.block)
            end
          end
        end
      end

      # Whether a dependent association can be resolved for a whole collection in a single existence query. Conservative on purpose: anything that
      # would make a flat `WHERE foreign_key IN (...)` query incorrect falls back to the per-record block.
      def batchable_feasibility_assoc?(assoc)
        return false unless %i[has_many has_one].include?(assoc.macro)
        return false if assoc.through_reflection         # has_*_through: join semantics, not a flat foreign key
        return false if assoc.options[:as]               # polymorphic inverse: needs a type column too
        return false if assoc.polymorphic?               # defensive; polymorphic on this side
        return false if assoc.scope&.arity&.positive? # scope needs the owner instance, can't merge onto a bare relation
        assoc.klass.present? && assoc.foreign_key.present?
      rescue StandardError
        # If anything about the reflection can't be resolved (e.g. STI / missing constant), prefer the safe per-record fallback.
        false
      end

      # Runs one existence query for `assoc` across all `records` and appends the prevention message to every record that has at least one
      # dependent row. See {precompute_feasibility}.
      def apply_batched_feasibility_prevention(records, action_name, prevention, assoc)
        ids = records.map(&:id).compact
        return if ids.empty?
        scope = assoc.klass.all
        scope = scope.instance_exec(&assoc.scope) if assoc.scope # honor static `has_many ..., -> { where(...) }` conditions
        # reorder(nil) drops any ORDER BY inherited from a default_scope or the association scope: PostgreSQL rejects
        # `SELECT DISTINCT ... ORDER BY <col>` when the ordering column is not in the select list, and ordering is irrelevant here anyway.
        triggered_ids = scope.where(assoc.foreign_key => ids).reorder(nil).distinct.pluck(assoc.foreign_key).to_set
        records.each do |record|
          record.instance_variable_get(:@feasibility_messages)[action_name] << prevention.message if triggered_ids.include?(record.id)
        end
      end

      # Provides Ransack defaults (auth_object must be a cancancan ability)
      def ransackable_attributes(auth_object)
        auth_object.permitted_attributes(:read, self).map(&:to_s)
      end
    end

    # Retrieves feasibility for the given instance, returning a boolean indicating whether the action is feasibly.
    # Calling this with an invalid action name will always return true.
    # This also generates appropriate error messages for any reason causing it to return false.
    # Feasilbility is cached, thus the second access will be faster.
    # @param action_name [Symbol,String] the action that the feasibility should be checked for, e.g. :destroy
    # @param recompute [Boolean] whether feasibility should be forcably recomputed even if a cached result is present
    def feasible?(action_name, recompute: false)
      action_name = action_name.to_sym
      @feasibility_messages ||= {}
      # Abort if check has already run and recompute is false
      if @feasibility_messages[action_name].nil? || recompute
        # Lazily autodetect feasibilities
        self.class.autodetect_feasibilities!
        # Compute feasibility and gather messages
        @feasibility_messages[action_name] = []
        feasibility_preventions[action_name]&.each do |prevention|
          if instance_exec(&prevention.block)
            @feasibility_messages[action_name] << prevention.message
          end
        end
      end
      return @feasibility_messages[action_name].none?
    end

    # Retrieves feasibility for the given instance and returns an array of reasons preventing the feasibility. Returns an empty array if feasible.
    # Conceptually, this is comparable to a model's `errors`.
    # @param action_name [Symbol,String] the action that the feasibility should be checked for, e.g. :destroy
    def feasibility_messages(action_name)
      action_name = action_name.to_sym
      feasible?(action_name) if @feasibility_messages&.[](action_name).nil? # If feasibility check hasn't been performed yet for this action, perform it now
      return @feasibility_messages[action_name]
    end

    # Retrieves feasibility for the given instance and returns a string holding all reasons preventing the feasibility. Returns an empty string if feasible.
    # Messages are joined using commata. The first character is capitalized and a period is added to the end.
    # Conceptually, this is comparable to a model's `full_messages`.
    # @param action_name [Symbol,String] the action that the feasibility should be checked for, e.g. :destroy
    def full_feasibility_messages(action_name)
      text = feasibility_messages(action_name).join(', ').upcase_first
      text += '.' if text.present?
      return text
    end

    # Calls value_for on the desired field. Do not confuse with the static method field.
    def field(field_name, controller)
      fields[field_name.to_sym].value_for(self, controller:)
    end
  end
end
