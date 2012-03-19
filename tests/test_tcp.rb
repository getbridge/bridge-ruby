require "bridge"
require_relative "connection_dummy.rb"
require "test/unit"
 
class TestTcp < Test::Unit::TestCase
 
  def setup
    
  end
 
  def teardown
    ## Nothing really
  end
 
  
  def test_receive_data
    dummy = ConnectionDummy.new
    tcp = Bridge::Tcp.new nil, dummy
    
    messages = ['abc', 'efghij', 'klmnop', 'rs', 't', 'uvwxyz']
    messages_packed = messages.map do |arg|
      [arg.length].pack("N") + arg
    end
    
    messages_packed.each do |arg|
      tcp.receive_data arg
    end
    
    assert(dummy.onopened)
    assert_equal(messages, dummy.messages)
    
    
    5.times do
      dummy.messages = []
      
      message = messages_packed.join
      
      pieces = rand(message.length) + 1
      each_piece = message.length / pieces
       
      while message.length > 0
        if message.length > each_piece
          tcp.receive_data(message.slice!(0, each_piece))
        else
          tcp.receive_data(message.slice!(0..-1))
        end
      end      
      assert_equal(messages, dummy.messages)
    end
  end
end