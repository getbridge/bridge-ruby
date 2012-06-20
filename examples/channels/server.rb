require 'bridge-ruby'

EventMachine.run do

  #bridge = Bridge::Bridge.new(:api_key => 'myapikey')
  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh', :host=>'localhost', :port=>8090)

  class AuthHandler
    def initialize bridge
      @bridge = bridge
    end

    def join channel_name, handler, &callback
      @bridge.join_channel(channel_name, handler, false, &callback)
    end

    def join_writeable channel_name, secret_word, handler, &callback
      @bridge.join_channel(channel_name, handler, true, &callback) if secret_word == "secret123"
    end
  end

  bridge.publish_service('auth', AuthHandler.new(bridge))

  bridge.connect
end
