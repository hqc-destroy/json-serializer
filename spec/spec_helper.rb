require 'simplecov'

SimpleCov.start do
  add_group 'Lib', 'lib'
  add_group 'Tests', 'spec'
end
SimpleCov.minimum_coverage 90

require 'active_support/core_ext/object/json'
require 'fast_jsonapi'
require 'ffaker'
require 'rspec'
require 'jsonapi/rspec'
require 'byebug'
<<<<<<< HEAD
<<<<<<< HEAD
require 'active_model_serializers'
require 'oj'
<<<<<<< HEAD
require 'jsonapi/serializable'
require 'jsonapi-serializers'
=======
>>>>>>> 4312d02... Enable oj to AM for fair benchmark test
=======
>>>>>>> 2a791bd... Remove performance and skipped tests.
=======
require 'securerandom'
>>>>>>> c533634... Rewrite tests.

Dir[File.expand_path('spec/fixtures/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.include JSONAPI::RSpec

  config.mock_with :rspec
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
