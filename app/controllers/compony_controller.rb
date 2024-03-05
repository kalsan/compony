class ComponyController < ApplicationController
  # Init
  actions_without_authentication = []

  # Define a controller action for each route
  Components.constants.each do |family_cst|
    Components.const_get(family_cst).constants.each do |comp_cst|
      # Instanciate the component for later information extraction
      comp = Components.const_get(family_cst).const_get(comp_cst).new

      # Standalone configs are already grouped in a hash, one entry per name/path
      comp.standalone_configs.each_value do |standalone_config|
        # Ignore incomplete standalone configs (these come from parent classes )
        next if standalone_config[:path].blank?

        # Define controller action for each standalone config
        define_method(standalone_config.rails_action_name) do
          translated_verb = request.raw_request_method.downcase.to_sym
          translated_verb = :get if translated_verb == :head # Rails transparently converts HEAD to GET, so we must do the same for fetching the config.
          verb_config = standalone_config.verbs[translated_verb]
          Compony.comp_class_for!(comp_cst, family_cst).new.on_standalone_access(verb_config, self)
        end

        # Disable authentication for marked standalone configs
        actions_without_authentication << standalone_config.rails_action_name.to_sym if standalone_config.skip_authentication
      end
    end
  end

  if Compony.authentication_before_action.present?
    before_action Compony.authentication_before_action, except: actions_without_authentication
  end
end
