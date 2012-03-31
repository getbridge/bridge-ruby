require '../../lib/bridge'
require './test'

description = 'Basic RPC';
failureMessage = 'This implementation of the Bridge API is incapable of RPC.';

=begin
Passing this test means the following:

We can connect (it seems), we can publish a service, the callback to
publishService is called, and calling a method of getService works.

=end

EM::run do
  test = Test.new(failureMessage, 1, 3)

  bridge = Bridge::Bridge.new({:apiKey => 'abcdefgh'}).connect {
    test.advance 0
  }

  module ConsoleLogServer
    def self.log msg
      if msg == '123'
        test.advance 2
      else
        test.log('received ' + msg + ' but expected 123');
      end
      test.finish
    end
  end

  bridge.ready {
    bridge.publishService 'test_consolelog', ConsoleLogServer {
      test.advance 1
      bridge.getService('test_consolelog') {|service| service.log('123')}
    }
  }
end
