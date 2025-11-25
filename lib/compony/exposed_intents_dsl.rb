module Compony
  class ExposedIntentsDsl < Dslblend::Base
    def initialize(previously_exposed_intents)
      super()
      @exposed_intents = previously_exposed_intents
    end

    protected

    # DSL method
    # Adds or replaces an intent to those exposed by the component based on the intent name (override the name if you need to avoid a naming collision).
    # Intents specified this way can be retrieved and rendered by the parent component or by calling `root_intents` in case of standalone access.
    # @param [Symbol] before If specified, will insert the intent before the other.  When replacing, an element keeps its position unless `before:`` is passed.
    def add(*, before: nil, **)
      intent = Compony.intent(*, **)
      @exposed_intents.natural_push(intent.name, intent, before:)
    end

    # DSL method
    # Removes an exposed intent previously added to this component
    # @param [Symbol] intent_name The name of the intent to remove
    def remove(intent_name)
      existing_index = @exposed_intents.find_index { |el| el.name == intent_name.to_sym }
      if existing_index
        @exposed_intents.delete_at(existing_index)
      end
    end
  end
end
