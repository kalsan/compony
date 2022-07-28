# See https://api.rubyonrails.org/classes/Rails/Railtie.html
module Compony
  class Railtie < Rails::Railtie
    initializer 'compony.initialize' do
      ActiveSupport.on_load :action_controller_base do
        include Compony::ControllerMixin
      end
    end
  end
end
