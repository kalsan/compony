Rails.application.routes.draw do
  # For every standalone and verb registered by every component, add a route comp#family_component
  Compony.families.each do |family|
    family.constants.each do |comp_cst|
      comp = family.const_get(comp_cst).new
      # Standalone configs are already grouped in a hash, one entry per name/path
      comp.standalone_configs.each_value do |standalone_config|
        next if standalone_config[:path].blank? # Ignore incomplete standalone configs (these come from parent classes )
        match(
          standalone_config.path,
          to:  "compony##{standalone_config.rails_action_name}",
          as:  standalone_config.path_helper_name,
          via: standalone_config.verbs.keys
        )
      end
    end
  end
end
