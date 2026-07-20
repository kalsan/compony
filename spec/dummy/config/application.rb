require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

require 'compony'

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.hosts.clear
    config.secret_key_base = 'dummy-secret-key-base-for-tests-only'
    config.logger = Logger.new(nil)
    config.active_support.deprecation = :stderr
    config.action_dispatch.show_exceptions = :none
    config.action_controller.allow_forgery_protection = false
  end
end
