module Compony
  class Engine < Rails::Engine
    initializer 'compony.initialize' do
      ActiveSupport.on_load :action_controller_base do
        include Compony::ControllerMixin
      end
    end
  end
end
