require 'bridge'

EventMachine.run do
  
  module ChatHandler
  
    def self.msg name, msg
      puts name + ': ' + msg
    end
      
  end
  
  
  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh').connect
  
  bridge.join_channel('lobby', ChatHandler)
  
  
end


