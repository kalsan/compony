ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'
require 'rspec/rails'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
load File.expand_path('dummy/db/schema.rb', __dir__)

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
  Kernel.srand config.seed
end
