require 'flotype-bridge'

module ChatServer
  def self.join(name, handler, callback)
    puts("Got join request for #{name}.")
    Bridge::join_channel('lobby', handler, callback)
  end
end

start_server = lambda do
  puts("start_server called (from chatserver.rb)")
  on_client_join = lambda do |lobby|
    puts("Client joined lobby (#{lobby}).")
  end
  Bridge::publish_service('chatserver', ChatServer, on_client_join)
end

EM::run do
  Bridge::initialize({ 'api_key'   => 'abcdefgh',
                       'host'      => 'localhost',
                       'port'      => 8090,
                       'reconnect' => false })
  Bridge::ready(start_server)
end
