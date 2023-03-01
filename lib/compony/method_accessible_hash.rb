module Compony
  # @api description
  # This class is intended for configs with predefined interfaces and should be used with instances of Hash:<br>
  # Example:<br>
  # ```ruby
  # instance_of_a_hash = Compony::MethodAccessibleHash.new
  # instance_of_a_hash.merge!({ foo: :bar })
  # instance_of_a_hash.foo --> :bar
  # instance_of_a_hash.roo --> nil
  # ```
  # See: https://gist.github.com/kalsan/87826048ea0ade92ab1be93c0919b405
  class MethodAccessibleHash < Hash
    # Takes an optional hash as argument and constructs a new
    # MethodAccessibleHash.
    def initialize(hash = {})
      super()

      hash.each do |key, value|
        self[key.to_sym] = value
      end
    end

    # @private
    def merge(hash)
      super(hash.symbolize_keys)
    end

    # @private
    def method_missing(method, *args, &)
      if method.end_with?('=')
        name = method.to_s.gsub(/=$/, '')
        self[name.to_sym] = args.first
      else
        self[method.to_sym]
      end
    end

    # @private
    def respond_to_missing?(_method, _include_private = false)
      true
    end
  end
end
