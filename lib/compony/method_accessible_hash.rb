module Compony
  # @api description
  # This class is intended for configs with predefined interfaces and should be used with instances of Hash:<br>
  # Example:<br>
  # ```ruby
  # instance_of_a_hash = Compony::MethodAccessibleHash.new
  # instance_of_a_hash.merge!({ foo: :bar })
  # instance_of_a_hash.foo --> :bar
  # instance_of_a_hash.roo --> NoMethodError
  # ```
  class MethodAccessibleHash < Hash
    def method_missing(method, *args, &)
      key?(method) || super
      return self[method.to_sym]
    end

    def respond_to_missing?(method, include_private = false)
      key?(method.to_sym) || super
    end
  end
end
