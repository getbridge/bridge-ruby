require 'json'

module Bridge
  module Util
    
    def self.generateGuid
      (0..12).map{ ('a'..'z').to_a[rand(26)] }.joi
    end
    
    def self.serialize bridge, obj
      if obj.respond_to? :to_dict
        obj.to_dict
      elsif obj.is_a? Hash
        o = {}
        obj.each do |k, v|
          o[k] = serialize bridge, v
        end
        o
      elsif obj.is_a?(Array)
        obj.map do |v|
          serialize bridge, v
        end
        obj
      elsif obj.methods(false).length > 0
        # obj is a class instance or module
        bridge.store_object(obj, obj.methods(false)).to_dict
      elsif obj.respond_to?(:call)
        bridge.store_object(Callback.new(obj), ['callback']).to_dict
      else
        obj
      end
    end

    def self.unserialize bridge, obj
      obj.each do |k, v|
        if v.is_a? Hash
          puts '##', v, '##'
          if v.has_key? 'ref'
            ref = Reference.new(bridge, v['ref'], v['operations'])
            if v.has_key? 'operations' and v['operations'].length == 1 and v['operations'][0] == 'callback'
              obj[k] = CallbackReference.new(ref)
            else
              obj[k] = ref
            end
          else
            obj[k] = unserialize bridge, v
          end
          puts '%%', obj[k], '%%'
        end
      end
      obj
    end

    def self.info msg, level = 3
      #opts = Bridge::options
      #if level <= opts['log_level']
        puts msg
      #end
    end
    
    def self.warn msg, level = 2
      #opts = Bridge::options
      #if level <= opts['log_level']
        puts msg
      #end
    end

    def self.error msg, level = 1
      #opts = Bridge::options
      #if level <= opts['log_level']
        puts msg
      #end
    end
   
    def self.stringify obj
      JSON::generate obj
    end
   
    def self.parse str
      JSON::parse str
    end 
    
      
    class Callback
      def initialize fun, ref
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
          nil
        end
      end

      def methods bool
        [:callback]
      end

      def respond_to? atom
        atom.to_s == 'callback'
      end
    end
      
    class CallbackReference < Proc
      def initialize ref
        @ref = ref
      end

      def callback *args, &blk
        args << blk if blk
        @ref.callback *args 
      end

      def call *args, &blk
        args << blk if blk
        @ref.callback *args
      end

      def method atom
        if atom.to_s == 'callback'
          self
        else
          nil
        end
      end

      def methods bool
        [:callback]
      end

      def to_dict
        @ref.to_dict 'callback'
      end
      
      def respond_to? atom
        atom = atom.to_s
        atom == 'callback' || atom == 'to_dict'
      end
      
    end
    
  end
  
end
