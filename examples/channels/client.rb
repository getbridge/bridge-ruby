require 'bridge'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh', :host => 'localhost', :port => 8090)

  class ChatHandler
    def message sender, msg
      puts "#{sender}: #{msg}"
    end
  end

  bridge.connect

  auth = bridge.get_service('auth')
  auth.join(ChatHandler.new) do |channel, name|
    puts "Joined: #{name}"
    channel.message('steve', "Can write to channel:#{name}")
  end

end
