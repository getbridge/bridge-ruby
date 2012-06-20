require 'bridge-ruby'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'myapikey')

  class ChatHandler
    def message sender, msg
      puts "#{sender}: #{msg}"
    end
  end

  bridge.connect

  auth = bridge.get_service('auth')
  auth.join('bridge-lovers', 'secret123', ChatHandler.new) do |channel, name|
    puts "Joined: #{name}"
    channel.message('steve', 'Bridge is nifty')
  end

end
