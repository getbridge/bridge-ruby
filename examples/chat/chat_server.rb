require 'flotype-bridge'

module ChatServer
  def self.join(name, handler, callback)
    puts("Got join request for #{name}.")
    Flotype::Bridge::join_channel('lobby', handler, callback)
  end
end

start_server = lambda do
  puts("start_server called (from chatserver.rb)")
  on_client_join = lambda do |lobby|
    puts("Client joined lobby (#{lobby}).")
  end
  Flotype::Bridge::publish_service('chatserver', ChatServer, on_client_join)
end

EM::run do
  Flotype::Bridge::initialize({ 'api_key'   => 'abcdefgh',
                       'host'      => 'localhost',
                       'port'      => 8090,
                       'reconnect' => false })
  Flotype::Bridge::ready(start_server)
end
