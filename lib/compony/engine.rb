module ::Components; end

module Compony
  class Engine < Rails::Engine
    initializer 'compony.configure_eager_load_paths', before: :load_environment_hook, group: :all do
      # Allow app/components/foo/bar.rb to define constants Components::Foo::Bar and make sure components are eager loaded (needed for route generation etc.)
      Rails.autoloaders.main.push_dir(Rails.root.join('app', 'components'), namespace: ::Components)
      unless Rails.application.config.eager_load
        Rails.application.config.to_prepare do
          Rails.autoloaders.main.eager_load_dir(Rails.root.join('app', 'components'))
        end
      end
    end

    initializer 'compony.controller_mixin' do
      ActiveSupport.on_load :action_controller_base do
        include Compony::ControllerMixin
      end
    end
  end
end
