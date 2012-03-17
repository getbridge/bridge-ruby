require 'bridge'

EventMachine.run do
  
  module ChatHandler
  
    def self.msg name, msg
      puts name + ': ' + msg
    end
      
  end
  
  
  bridge = Bridge::Bridge.new(:host => 'localhost', :port => 8090, :api_key => 'abcdefgh') 
  
  bridge.join_channel('lobby', ChatHandler)
  
  
end


