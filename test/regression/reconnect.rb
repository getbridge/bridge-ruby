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
    def initialize(test, id)
      @id = id
      @test = test
      @test.advance 1
    end

    def cb(id)
      if id != @id
        @test.fail "ID not preserved."
      end
      @test.advance 3
      @test.close
    end
  end

  bridge = Bridge::Bridge.new({:api_key => 'abcdefgh'}).connect {
    test.advance 0
  }

  bridge.ready {
    svc = T.new(test, bridge.connection.client_id)
    bridge.publish_service('test_reconn', svc) {
      test.advance 2
      bridge.connection.sock.close_connection
      EM::Timer.new(0) {
        bridge.get_service('test_reconn') {|service| service.cb(bridge.connection.client_id)}
      }
    }
  }
end
