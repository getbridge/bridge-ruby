require "bridge"
require_relative "bridge_dummy.rb"
require "test/unit"
 
class TestUtil < Test::Unit::TestCase
 
  def setup
    
  end
 
  def teardown
    ## Nothing really
  end
 
  def test_generate_guid
    ids = {}
    (1..10).each do
      id = Bridge::Util.generate_guid
      assert_equal(13, id.length)        
      assert(!ids.key?(id))
      ids[id] = true
    end
  end
 
  def test_stringify_and_parse
    data = {'a' => 1, 'b' => "test code", 'c' => {}, 'd' => [1,false,nil,"asdf",{'a' => 1, 'b' => 2}]}
    assert_equal(Bridge::Util.parse(Bridge::Util.stringify(data)), data)
  end
  
  def test_ref_callback
    dummy = BridgeDummy.new
    dest = ['x', 'x', 'x']
    
    dest_ref = Bridge::Reference.new(dummy, dest + ["callback"]).to_dict
    
    ref = Bridge::Reference.new dummy, dest
    
    cb = Bridge::Util.ref_callback ref
    
    assert_instance_of(Bridge::Util::CallbackReference, cb)
    assert_equal(ref.to_dict, cb.to_dict)
    
    args = [1,2,3]
    blk = lambda {1}
    args << blk
    cb.call args, &blk
    
    assert_equal(args, *dummy.last_args)
    assert_equal(dest_ref, dummy.last_dest)
    
    args = [4,5,6]
    blk = lambda {2}
    args << blk
    cb.callback args, &blk
    
    assert_equal(args, *dummy.last_args)
    assert_equal(dest_ref, dummy.last_dest)
  end
end