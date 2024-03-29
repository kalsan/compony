module Compony
  class Component
    # Include all functionality that was moved to default mixins for better overview
    Compony::ComponentMixins::Default.constants.each { |cst| include Compony::ComponentMixins::Default.const_get(cst) }

    class_attribute :setup_blocks

    attr_reader :parent_comp
    attr_reader :comp_opts

    # root comp: component that is registered to be root of the application.
    # parent comp: component that is registered to be the parent of this comp. If there is none, this is the root comp.

    # DSL method
    def self.setup(&block)
      fail("`setup` expects a block in #{inspect}.") unless block_given?
      self.setup_blocks ||= []
      self.setup_blocks = setup_blocks.dup # This is required to prevent the parent class to see children's setup blocks.
      setup_blocks << block
    end

    def initialize(parent_comp = nil, index: 0, **comp_opts)
      @parent_comp = parent_comp
      @sub_comps = []
      @index = index
      @comp_opts = comp_opts
      @before_render_block = nil
      @content_blocks = []
      @actions = []
      @skipped_actions = Set.new

      init_standalone
      init_labelling

      fail "#{inspect} is missing a call to `setup`." unless setup_blocks&.any?

      setup_blocks.each do |setup_block|
        instance_exec(&setup_block)
      end
    end

    def inspect
      "#<#{self.class.name}:#{hash}>"
    end

    # Returns the current root comp.
    # Do not overwrite.
    def root_comp
      return self unless parent_comp
      return parent_comp.root_comp
    end

    # Returns whether or not this is the root comp.
    # Do not overwrite.
    def root_comp?
      parent_comp.nil?
    end

    # Returns an identifier describing this component. Must be unique among simplings under the same parent_comp.
    # Do not override.
    def id
      "#{family_name}_#{comp_name}_#{@index}"
    end

    # Returns the id path from the root_comp.
    # Do not overwrite.
    def path
      if root_comp?
        id
      else
        "#{parent_comp.path}/#{id}"
      end
    end

    # Returns a hash for the path. Used for params prefixing.
    # Do not overwrite.
    def path_hash
      Digest::SHA1.hexdigest(path)[..4]
    end

    # Given an unprefixed name of a param, adds the path hash
    # Do not overwrite.
    def param_name(unprefixed_param_name)
      "#{path_hash}_#{unprefixed_param_name}"
    end

    # Instanciate a component with `self` as a parent
    def sub_comp(component_class, **comp_opts)
      sub = component_class.new(self, index: @sub_comps.count, **comp_opts)
      @sub_comps << sub
      return sub
    end

    # Returns the name of the module constant (=family) of this component. Do not override.
    def family_cst
      self.class.module_parent.to_s.demodulize.to_sym
    end

    # Returns the family name
    def family_name
      family_cst.to_s.underscore
    end

    # Returns the name of the class constant of this component. Do not override.
    def comp_cst
      self.class.name.demodulize.to_sym
    end

    # Returns the component name
    def comp_name
      comp_cst.to_s.underscore
    end

    # @todo deprecate (check for usages beforehand)
    def comp_class_for(...)
      Compony.comp_class_for(...)
    end

    # @todo deprecate (check for usages beforehand)
    def comp_class_for!(...)
      Compony.comp_class_for!(...)
    end

    # DSL method
    def before_render(&block)
      @before_render_block = block
    end

    # DSL method
    # Overrides previous content (also from superclasses). Will be the first content block to run.
    # You can use dyny here.
    def content(&block)
      fail("`content` expects a block in #{inspect}.") unless block_given?
      @content_blocks = [block]
    end

    # DSL method
    # Adds a content block that will be executed after all previous ones.
    # It is safe to use this method even if `content` has never been called
    # You can use dyny here.
    def add_content(index = -1, &block)
      fail("`content` expects a block in #{inspect}.") unless block_given?
      @content_blocks ||= []
      @content_blocks.insert(index, block)
    end

    # Renders the component using the controller passsed to it and returns it as a string.
    # @param [Boolean] standalone pass true iff `render` is called from `render_standalone`
    # Do not overwrite.
    def render(controller, standalone: false, **locals)
      # Call before_render hook if any and backfire instance variables back to the component
      # TODO: Can .request_context be removed from the next line? Test well!
      RequestContext.new(self, controller, locals:).request_context.evaluate_with_backfire(&@before_render_block) if @before_render_block
      # Render, unless before_render has already issued a body (e.g. through redirecting).
      if controller.response_body.nil?
        fail "#{self.class.inspect} must define `content` or set a response body in `before_render`" if @content_blocks.none?
        return controller.render_to_string(
          type:   :dyny,
          locals: { content_blocks: @content_blocks, standalone:, component: self, render_locals: locals },
          inline: <<~RUBY
            if Compony.content_before_root_comp_block && standalone
              Compony::RequestContext.new(component, controller, helpers: self, locals: render_locals).evaluate(&Compony.content_before_root_comp_block)
            end
            content_blocks.each do |block|
              # Instanciate and evaluate a fresh RequestContext in order to use the buffer allocated by the ActionView (needed for `concat` calls)
              Compony::RequestContext.new(component, controller, helpers: self, locals: render_locals).evaluate(&block)
            end
            if Compony.content_after_root_comp_block && standalone
              Compony::RequestContext.new(component, controller, helpers: self, locals: render_locals).evaluate(&Compony.content_after_root_comp_block)
            end
          RUBY
        )
      else
        return nil # Prevent double render errors
      end
    end

    # DSL method
    # Adds or replaces an action (for action buttons)
    # If before: is specified, will insert the action before the named action. When replacing, an element keeps its position unless before: is specified.
    def action(action_name, before: nil, &block)
      action_name = action_name.to_sym
      before_name = before&.to_sym
      action = MethodAccessibleHash.new(name: action_name, block:)

      existing_index = @actions.find_index { |el| el.name == action_name }
      if existing_index.present? && before_name.present?
        @actions.delete_at(existing_index) # Replacing an existing element with a before: directive - must delete before calculating indices
      end
      if before_name.present?
        before_index = @actions.find_index { |el| el.name == before_name } || fail("Action #{before_name} for :before not found in #{inspect}.")
      end

      if before_index.present?
        @actions.insert(before_index, action)
      elsif existing_index.present?
        @actions[existing_index] = action
      else
        @actions << action
      end
    end

    # DSL method
    # Marks an action for skip
    def skip_action(action_name)
      @skipped_actions << action_name.to_sym
    end

    # Used to render all actions of this component, each button wrapped in a div with the specified class
    def render_actions(controller, wrapper_class: '', action_class: '')
      h = controller.helpers
      h.content_tag(:div, class: wrapper_class) do
        button_htmls = @actions.map do |action|
          next if @skipped_actions.include?(action.name)
          Compony.with_button_defaults(feasibility_action: action.name.to_sym) do
            action_button = action.block.call(controller)
            next unless action_button
            button_html = action_button.render(controller)
            next if button_html.blank?
            h.content_tag(:div, button_html, class: action_class)
          end
        end
        next h.safe_join button_htmls
      end
    end

    # Is true for resourceful components
    def resourceful?
      return false
    end
  end
end
