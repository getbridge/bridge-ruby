require 'flotype-bridge'
require 'eventmachine'

module MsgHandler
  include Flotype::Bridge::Service
  def self.msg(name, message)
    puts(name + ': ' + message)
  end
end

class LobbyHandler
  include Flotype::Bridge::Service
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
  chat = Flotype::Bridge::get_service('chatserver')
  puts 'sending a join.'
  chat.join('lobby', MsgHandler, lobby)
}

EM::run do
  Flotype::Bridge::initialize({ 'api_key'   => 'abcdefgh',
                       'reconnect' => false })
  Flotype::Bridge::ready(start_client)
end
