require 'json'
require 'util.rb'

module Bridge
  module Serializer #:nodoc: all
    
     def self.serialize bridge, obj
      # Serialize immediately if obj responds to to_dict
      if obj.respond_to? :to_dict
        result = obj.to_dict
      # Enumerate hash and serialize each member
      elsif obj.is_a? Hash
        result = {}
        obj.each do |k, v|
          result[k] = serialize bridge, v
        end
      # Enumerate array and serialize each member
      elsif obj.is_a? Array
        result = obj.map do |v|
          serialize bridge, v
        end
      # Store as callback if callable
      elsif obj.respond_to?(:call)
        result = bridge.store_object(Callback.new(obj), ['callback']).to_dict
      # Return obj itself is JSON serializable
      elsif JSON::Ext::Generator::GeneratorMethods.constants.include? obj.class.name.to_sym
        result = obj
      # Otherwise store as service. Obj is a class instance or module
      else
        result = bridge.store_object(obj, Util.find_ops(obj)).to_dict  
      end
      return result
    end

    def self.unserialize bridge, obj
      if obj.is_a? Hash
        obj.each do |k, v|
          unserialize_helper bridge, obj, k, v
        end
      elsif obj.is_a? Array
        obj.each_with_index do |v, k|
          unserialize_helper bridge, obj, k, v
        end
      end
    end
    
    def self.unserialize_helper bridge, obj, k, v
      if v.is_a? Hash
        # If object has ref key, convert to reference
        if v.has_key? 'ref'
          # Create reference
          ref = Reference.new(bridge, v['ref'], v['operations'])
          if v.has_key? 'operations' and v['operations'].length == 1 and v['operations'][0] == 'callback'
            # Callback wrapper
            obj[k] = Util.ref_callback ref
          else
            obj[k] = ref
          end
          return
        end
      end
      unserialize bridge, v
    end
    
    class Callback
      def initialize fun
        @fun = fun
      end

      def callback *args
        @fun.call *args
      end

      def call *args
        @fun.call(*args)
      end

      def method atom
        if atom.to_s == 'callback'
          @fun
        else
          Class.method atom
        end
      end

      def methods bool
        [:callback]
      end

      def respond_to? atom
        atom.to_s == 'callback' || Class.respond_to?(atom)
      end
      
    end
    
  end
end
