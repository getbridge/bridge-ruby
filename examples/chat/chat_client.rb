require 'bridge' 
require 'eventmachine'

class MsgHandler
  include Bridge::Service
  def msg(name, message)
    puts(name + ': ' + message)
  end
end

class LobbyHandler
  include Bridge::Service
  def initialize(name)
    @name = name
    @lobby = nil
  end

  def call(channel)
    @lobby = channel
    self.send('Hello, world.')
  end

  def send(message)
    @lobby.msg(@name, message)
  end
end

start_client = lambda {
  lobby = LobbyHandler.new('Vedant')
  chat = Bridge::get_service('chatserver')
  puts 'sending a join.'
  chat.join('lobby', MsgHandler, lobby)
}

EM::run do
  Bridge::initialize({ 'api_key'   => 'abcdefgh',
                       'host'      => 'localhost',
                       'port'      => 8090,
                       'reconnect' => false })
  Bridge::ready(start_client)
end
