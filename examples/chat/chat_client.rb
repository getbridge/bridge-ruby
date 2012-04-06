require 'bridge'

EventMachine.run do
  
  module ChatHandler
  
    def self.msg name, msg
      puts name + ': ' + msg
    end
      
  end
  
  
  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh').connect do
    puts 'connected'
    bridge.on 'remote_error' do | msg |
      puts msg
    end
    bridge.publish_service 'test.', Bridge
  end
  
  ##bridge.join_channel('lobby', ChatHandler)
  
  
end


