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
  #
  # collection.names # --> :a, :b, :c
  # collection.payloads # --> a_payload, b_payload, c_payload
  # ```
  class NaturalOrdering < Array
    def natural_push(name, payload, before: nil)
      name = name.to_sym
      before_name = before&.to_sym
      action = MethodAccessibleHash.new(name:, payload:)

      existing_index = find_index { |el| el.name == name }
      if existing_index.present? && before_name.present?
        delete_at(existing_index) # Replacing an existing element with a before: directive - must delete before calculating indices
      end
      if before_name.present?
        before_index = find_index { |el| el.name == before_name } || fail("Action #{before_name} for :before not found in #{inspect}.")
      end

      if before_index.present?
        insert(before_index, action)
      elsif existing_index.present?
        self[existing_index] = action
      else
        self << action
      end
    end

    def names
      map(&:name)
    end

    def payloads
      map(&:payload)
    end
  end
end
