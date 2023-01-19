module Compony
  class Engine < Rails::Engine
    initializer 'compony.configure_eager_load_paths', before: :load_environment_hook, group: :all do
      # Allow app/components/foo/bar.rb to define constants Components::Foo::Bar and make sure components are eager loaded (needed for route generation etc.)
      Rails.application.config.eager_load_paths.delete(Rails.root.join('app', 'components').to_s)
      Rails.application.config.eager_load_paths.unshift(Rails.root.join('app').to_s)

      # Prevent *.rb files in assets and views directories to be loaded
      Rails.autoloaders.main.ignore(Rails.root.join('app', 'assets').to_s)
      Rails.autoloaders.main.ignore(Rails.root.join('app', 'views').to_s)
    end

    initializer 'compony.controller_mixin' do
      ActiveSupport.on_load :action_controller_base do
        include Compony::ControllerMixin
      end
    end
  end
end
