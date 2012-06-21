require 'bridge-ruby'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'myapikey')

  class PongObject
    def pong
      puts "PONG!"
    end
  end

  bridge.connect

  bridge.store_service("pong", PongObject.new)

  pinger = bridge.get_service('ping')
  pinger.ping

end

