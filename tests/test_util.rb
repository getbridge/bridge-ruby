require "bridge"
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
      assert_equal(12, id.length)        
      assert(!ids.key?(id))
      ids[id] = true
    end
    
  end
 
end