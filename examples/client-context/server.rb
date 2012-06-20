require 'bridge-ruby'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'myapikey')

  class Test

    def initialize bridge
      @bridge = bridge
    end

    def someFunction
      client = @bridge.context
      client.get_service("thank").thank("thank you come again")
    end
  end

  bridge.connect

  bridge.publish_service("test", Test.new(bridge))

end

