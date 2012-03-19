require "bridge"
require_relative "bridge_dummy.rb"
require_relative "reference_dummy.rb"
require "test/unit"
 
class TestSerializer < Test::Unit::TestCase
 
  def setup
    
  end
 
  def teardown
    ## Nothing really
  end
 
  
  def test_serialize
    dummy = BridgeDummy.new
    test2 = Test2.new
    test3 = Test3.new
    test4 = lambda {}
    obj = {
      :a => {
        :b => Test1
      },
      :c => 5,
      :d => true,
      :e => 'abc',
      :f => [test2, test3],
      :g => test2,
      :h => test3,
      :i => test4
    }
    ser = Bridge::Serializer.serialize dummy, obj
    
    assert(dummy.stored.include?([Test1, [:a]]))
    assert(dummy.stored.include?([test2, [:c]]))
    assert(dummy.stored.include?([test3, [:d, :e]]))
    
    found = false
    dummy.stored.each do | x |
      if x[1] == ['callback']
        assert_instance_of(Bridge::Serializer::Callback, x[0])
        found = true
      end
    end
    
    assert found
   
    expected_ser = {
      :a => {
        :b => "dummy"
      },
      :c => 5,
      :d => true,
      :e => 'abc',
      :f => ["dummy", "dummy"],
      :g => "dummy",
      :h => "dummy",
      :i => "dummy"
    }
   
    assert_equal(expected_ser, ser)
  end
  
  def test_unserialize
    dummy = BridgeDummy.new
    obj = {
      :a => {'ref' => ['x','x','x'], 'operations' => ['a','b']},
      :b => {
        :i => {'ref' => ['z','z','z'], 'operations' => ['callback']}
      },
      :c => 5,
      :d => true,
      :e => 'abc',
      :f => [1, {'ref' => ['y','y','y'], 'operations' => ['c','d']}],
      :g => 2,
      :h => 'foo'
    }
    
    unser = Bridge::Serializer.unserialize dummy, obj
    
    assert_instance_of(Bridge::Reference, unser[:a])
    assert_instance_of(Bridge::Reference, unser[:f][1])
    assert_instance_of(Bridge::Util::CallbackReference, unser[:b][:i])
    
    
  end
  
  module Test1
    def self.a
    end
    def b
    end
  end
  
  class Test2
    def c
    end
  end
  
  class Test3 < Test2
    def d
    end
    def e
    end
  end
  
end