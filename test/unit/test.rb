require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

require 'test/unit'

require_relative '../../lib/bridge'
require_relative '../../lib/connection'
require_relative '../../lib/reference'
require_relative '../../lib/serializer'
require_relative '../../lib/tcp'
require_relative '../../lib/util'
require_relative '../../lib/version'

require_relative 'test_util.rb'
require_relative 'test_serializer.rb'
require_relative 'test_tcp.rb'
require_relative 'test_reference.rb'

