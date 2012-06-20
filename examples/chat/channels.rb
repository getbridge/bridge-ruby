    require 'bridge-ruby'

    EventMachine.run do

      bridge = Bridge::Bridge.new(:api_key => 'abcdefgh', :log => 5, :secure => true)

      class ChatHandler
        def message sender, msg
          print sender, ":", msg
        end
      end

      bridge.connect
      bridge.join_channel('bridge-lovers', ChatHandler.new) do |channel, name|
        print "Joined: ", name
        channel.message('steve', 'Flotype Bridge is nifty')
      end

    end
