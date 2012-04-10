require 'bridge'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'myapikey')

  class AuthHandler
    def initialize bridge
      @bridge = bridge
    end

    def join name, password, handler, &callback
      if password == 'secret123'
        @bridge.join_channel(name, handler, &callback)
        puts 'Welcome!'
      else
        puts 'Sorry!'
      end
    end
  end

  bridge.connect
  bridge.publish_service('auth', AuthHandler.new(bridge))
end