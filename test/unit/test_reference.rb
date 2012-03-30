require "bridge"
require_relative "bridge_dummy.rb"
require "test/unit"
 
class TestReference < Test::Unit::TestCase
 
  def setup
    
  end
 
  def teardown
    ## Nothing really
  end
 
  
  def test_reference
    dummy = BridgeDummy.new
    ref = Bridge::Reference.new dummy, ['x', 'y', 'z'], [:a, :b, :c]
    assert_equal(['a', 'b', 'c'], ref.operations)
    assert_equal({:ref => ['x', 'y', 'z'], :operations => ['a', 'b', 'c']}, ref.to_dict)
    
    blk = lambda {}
    ref.test 1, 2, &blk
    assert_equal([1,2,blk], dummy.last_args)
    assert_equal(['x', 'y', 'z', 'test'], dummy.last_dest[:ref])
    assert(!dummy.last_dest.key?(:operations))
    
  end
  
end