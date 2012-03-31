require_relative '../../lib/bridge'
require_relative './test'

description = 'Reconnects';
failureMessage = 'This implementation of the Bridge API does not support reconnects.';

=begin
Passing this test means the following:

We can connect, reconnects (seem to) work. buffering between reconnects
works, services are preserved between these reconnects (i.e. should happen
in < 5s), and client ID is preserved.
=end

EM::run do
  test = Test.new(failureMessage, 1, 4)

  class T
    def initialize id
      @id = id
      test.advance 1
    end

    def cb id
      if id != @id
        fail "ID not preserved."
      end
      advance 3
      test.close
    end
  end

  bridge = Bridge::Bridge.new({:apiKey => 'abcdefgh'}).connect {
    test.advance 0
  }

  bridge.ready {
    svc = T.new(bridge.connection.client_id)
    bridge.publishService('test_reconn', svc) {
      test.advance 2
      bridge.connection.sock.close_connection
      bridge.getService('test_reconn') {|service| service.cb(bridge.connection.client_id)}
    }
  }
end
