module Compony
  # @api description
  # This class provides an array-based data structure where elements have symbol names. New elements can be appended or placed at a location using `before:`.
  # Important: do not mutate this class with any other method call than the natural_-prefixed methods defined below.
  # Example:<br>
  # ```ruby
  # collection = Compony::NaturalOrdering.new
  # collection.natural_push(:a, a_payload)
  # collection.natural_push(:c, c_payload)
  # collection.natural_push(:b, b_payload, before: :c)
  # collection.natural_push(:d, d_payload, hidden: true)
  # collection.natural_push(:a, a_new_payload) # overwrites :a
  #
  # collection.reject{|el| el.hidden}.map(&:name) # --> :a, :b, :c
  # collection.map(&:payload) # --> a_new_payload, b_payload, c_payload, d_payload
  # ```
  class NaturalOrdering < Array
    def natural_push(name, payload, before: nil, **kwargs)
      name = name.to_sym
      before_name = before&.to_sym
      element = MethodAccessibleHash.new(name:, payload:, **kwargs)

      existing_index = find_index { |el| el.name == name }
      if existing_index.present? && before_name.present?
        delete_at(existing_index) # Replacing an existing element with a before: directive - must delete before calculating indices
      end
      if before_name.present?
        before_index = find_index { |el| el.name == before_name } || fail("Element #{before_name.inspect} for :before not found in #{inspect}.")
      end

      if before_index.present?
        insert(before_index, element)
      elsif existing_index.present?
        self[existing_index] = element
      else
        self << element
      end
    end
  end
end
