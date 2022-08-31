module Compony
  class AttrGroup
    class FormHelper
      attr_reader :attr_group
      attr_reader :form
      attr_reader :comp

      def initialize(attr_group, form, comp)
        @attr_group = attr_group
        @form = form
        @comp = comp
      end

      def attr(attr_key)
        case @attr_group.attrs[attr_key.to_sym]
        when :attribute
          return @form.input attr_key
        when :password
          return @form.input attr_key, as: :password
        when :association
          return @form.association attr_key
        when nil
          fail "Attr key #{attr_key} does not exist in attr_group #{attr_group.inspect}"
        else
          fail "Unknown attr mode #{@mode}, AttrGroup should have prevented this."
        end
      end
    end
  end
end
