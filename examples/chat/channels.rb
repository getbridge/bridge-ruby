    require 'bridge'

    EventMachine.run do

      bridge = Bridge::Bridge.new(:api_key => 'abcdefgh', :log => 5, :secure => true)

      class ChatHandler
        def message sender, msg
          print sender, ":", msg
        end
      end

      bridge.connect
      bridge.join_channel('flotype-lovers', ChatHandler.new) do |channel, name|
        print "Joined: ", name
        channel.message('steve', 'Flotype Bridge is nifty')
      end

    end
