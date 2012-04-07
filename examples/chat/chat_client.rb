require 'bridge'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh', :log => 5)

  class ChatHandler
    def message sender, msg
      print sender, ":", msg
    end
  end


  bridge.connect

  auth = bridge.get_service('auth')
  auth.join('flotype-lovers', 'secret123', ChatHandler.new) do |channel, name|
    print "Joined: ", name
  end

end

