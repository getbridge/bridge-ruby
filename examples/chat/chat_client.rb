require 'bridge' 
require 'eventmachine'

module MsgHandler
  def self.msg(name, message)
    puts(name + ': ' + message)
  end
end

class LobbyHandler
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

def start_client
  lobby = LobbyHandler.new('Vedant')
  chat = Bridge::get_service('chatserver')
  puts 'sending a join.'
  chat.join('lobby', MsgHandler, lobby)
end

EM::run do
  Bridge::initialize({ 'api_key'   => 'abcdefgh',
                       'host'      => '127.0.0.1',
                       'port'      => 8090,
                       'reconnect' => false })
  Bridge::ready(start_client)
end
