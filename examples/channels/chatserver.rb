require 'bridge'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh', :host => 'localhost', :port => 8090)

  class AuthHandler
    def initialize bridge
      @bridge = bridge
    end

    def join handler, &callback
      @bridge.join_channel('+rw', handler, &callback)
      @bridge.join_channel('+r', handler, false, &callback)
    end
  end

  bridge.connect
  bridge.publish_service('auth', AuthHandler.new(bridge))
end
