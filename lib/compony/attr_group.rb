module Compony
  class AttrGroup
    attr_reader :name
    attr_reader :attrs

    def initialize(name, base_attr_group: nil)
      @name = name
      @attrs = base_attr_group&.attrs&.dup || {}
    end

    def translation_key_for(data_or_data_class, attr_key)
      "#{data_or_data_class.model_name.name}|#{attr_key.to_s.humanize}"
    end

    # rubocop:disable Naming/MethodParameterName
    def add(*attr_names, as: :attribute)
      as = as.to_sym
      unless Attr::ACCEPTED_MODES.include?(as)
        fail "AttrGroup #{name} was given invalid mode #{as}, supported are: #{ACCEPTED_MODES}"
      end
      attr_names.each do |attr_name|
        attr_name = attr_name.to_sym
        fail "AttrGroup #{name} already has an attribute #{attr_name.to_sym.inspect}" if @attrs.key?(attr_name)
        @attrs[attr_name] = as
      end
    end
    # rubocop:enable Naming/MethodParameterName

    def del(*attr_names)
      attr_names.each do |attr_name|
        attr_name = attr_name.to_sym
        fail "AttrGroup #{name} does not have an attribute #{attr_name.to_sym.inspect}" unless @attrs.key?(attr_name)
        @attrs.delete(attr_name)
      end
    end

    # Used in infocard
    def each_attr_for(data)
      @attrs.each do |attr_key, mode|
        yield Attr.new(self, attr_key, mode, data)
      end
    end

    # Used in form
    def form_helper_for(form, comp)
      FormHelper.new(self, form, comp)
    end
  end
end