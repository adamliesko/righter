require 'codeclimate-test-reporter'
require 'coveralls'

CodeClimate::TestReporter.start

Coveralls.wear!
# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../../test/dummy/config/environment.rb', __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path('../../test/dummy/db/migrate', __FILE__)]

ActiveRecord::Migrator.migrate File.expand_path('../../db/migrate/', __FILE__)
ActiveRecord::Migrator.migrate File.expand_path('../dummy/db/migrate/', __FILE__)

require 'rails/test_help'
require 'factory_girl_rails'

FactoryGirl.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryGirl.find_definitions
# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.

Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.fixtures :all
end

def sign_in(user)
  User.current_user = user
end

def sign_out
  User.current_user = nil
end

def count_queries(&block)
  count = 0

  counter_f = ->(_name, _started, _finished, _unique_id, payload) {
    count += 1 unless payload[:name].in? %w( CACHE SCHEMA )
  }

  ActiveSupport::Notifications.subscribed(counter_f, 'sql.active_record', &block)

  count
end
