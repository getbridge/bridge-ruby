require 'bridge'

EventMachine.run do
  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh')
  bridge.connect


  #
  # Joining a Bridge channel
  #
  # In order to join a Bridge channel, clients must provide the name 
  # of the channel to join and a handler object on which RPC calls 
  # in the channel will act on. Note that the client that is joined 
  # to the channel is whoever created the handler, not necessarily the 
  # client executing the join command. This means clients can join other
  # clients to channels by having a reference to an object of theirs.
  #
  # Only Bridge clients using the private API key may call the join command. 
  # However, those clients may join other clients using the public API key on their behalf.
  #
  class TestHandler
    def log msg
      puts "Got message: #{msg}"
    end
  end

  bridge.join_channel 'testChannel', TestHandler.new do
    ready bridge
  end

  def ready bridge
    #
    # Getting and calling a Bridge channel
    #
    # This can be done from any Bridge client connected to the same 
    # Bridge server, regardless of language.
    # When a function call is made to a channel object, the requested
    # function will be executed on everyone in the channel
    # 
    # Only Bridge clients using the private API key may call the join command. 
    #
    bridge.get_channel 'testChannel' do |testChannel, name|
      puts 'Sending message'
      testChannel.log 'hello'
    end
  end
end