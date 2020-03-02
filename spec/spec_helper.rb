require 'simplecov'

SimpleCov.start do
  add_group 'Lib', 'lib'
  add_group 'Tests', 'spec'
end
SimpleCov.minimum_coverage 90

require 'active_record'
require 'fast_jsonapi'
require 'byebug'
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

Dir[File.dirname(__FILE__) + '/shared/contexts/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/shared/examples/*.rb'].each {|file| require file }
