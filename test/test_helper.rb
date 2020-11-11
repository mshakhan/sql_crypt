# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"

require 'rails/test_help'
require 'sql_crypt'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/test.log")
ActiveRecord::Base.configurations = { 'test' => config[ENV['DB'] || 'mysql2'] }
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])

load(File.dirname(__FILE__) + "/schema.rb")

class ActiveSupport::TestCase

  include ActiveRecord::TestFixtures
  self.fixture_path = File.dirname(__FILE__) + "/fixtures"
  self.use_transactional_tests = false
  self.use_instantiated_fixtures = false

  fixtures :all

  @@expectations = YAML::load(IO.read(File.dirname(__FILE__) + '/expected_by_db.yml'))
end
