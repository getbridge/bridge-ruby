require 'bridge'

module ChatServer
  def self.join(name, handler, callback)
    print("Got join request for #{name}.")
    Bridge::join_channel('lobby', handler, callback)
  end
end

start_server = lambda do
  print("start_server called (from chatserver.rb)")
  on_client_join = lambda do |lobby|
    print("Client joined lobby (#{lobby}).")
  end
  Bridge::publish_service('chatserver', ChatServer, on_client_join)
end

EM::run do
  Bridge::initialize({ 'api_key'   => 'abcdefgh',
                       'reconnect' => false })
  Bridge::ready(start_server)
end
