require 'bridge-ruby'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'myapikey')

  class PingObject

    def initialize bridge
      @bridge = bridge
    end

    def ping
      puts "PING!"
      client = @bridge.context
      client.get_service("pong").pong()
    end
  end

  bridge.publish_service("ping", PingObject.new(bridge))

  bridge.connect

end

