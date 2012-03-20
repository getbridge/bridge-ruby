require 'json'
require 'util.rb'

module Bridge
  module Serializer #:nodoc: all
    
     def self.serialize bridge, obj
      if obj.respond_to? :to_dict
        result = obj.to_dict
      elsif obj.is_a? Hash
        result = {}
        obj.each do |k, v|
          result[k] = serialize bridge, v
        end
      elsif obj.is_a? Array
        result = obj.map do |v|
          serialize bridge, v
        end
      elsif obj.respond_to?(:call)
        result = bridge.store_object(Callback.new(obj), ['callback']).to_dict
      elsif JSON::Ext::Generator::GeneratorMethods.constants.include? obj.class.name.to_sym
        result = obj
      elsif obj.is_a? Module
        # obj is a class instance or module
        result = bridge.store_object(obj, obj.methods(false)).to_dict
      else
        result = bridge.store_object(obj, obj.class.instance_methods(false)).to_dict
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
        if v.has_key? 'ref'
          ref = Reference.new(bridge, v['ref'], v['operations'])
          if v.has_key? 'operations' and v['operations'].length == 1 and v['operations'][0] == 'callback'
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
