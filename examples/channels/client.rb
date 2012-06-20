require 'bridge-ruby'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'myapikey')

  class ChatHandler
    def message sender, msg
      puts "#{sender}: #{msg}"
    end
  end


  auth = bridge.get_service('auth')
  auth.join("bridge-lovers", ChatHandler.new) do |channel, name|
    puts "Joined channel: #{name}"
    # The following RPC call will fail because client was not joined to channel with write permissions
    channel.message('steve', "This should not work.")
  end

  bridge.connect

end
