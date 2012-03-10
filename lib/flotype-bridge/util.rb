require 'json'

module Flotype
  module Bridge
    module Util
      # Traverses an object, replacing funs with refs.
      def self.inflate obj
        if obj.is_a?(Array)
          obj.map do |v|
            bloat v
          end
        else
          o = {}
          obj.each do |k, v|
            o[k] = bloat v
          end
          o
        end
      end
      
      def self.bloat v
        if v.is_a?(Module) || v.is_a?(Flotype::Bridge::Service)
          local_ref(v)
        elsif v.respond_to?(:call) && !v.is_a?(Ref)
          cb(v)
        elsif v.is_a?(Hash) || v.is_a?(Array)
          inflate v
        else
          v
        end
      end
      
      def self.deflate obj
        if obj.is_a?(Array)
          obj.map do |v|
            deflate v
          end
        elsif obj.is_a? Hash
          if obj.has_key? 'ref'
            Core::lookup obj['ref']
          else
            o = {}
            obj.each do |k, v|
              o[k] = deflate v
            end
            o
          end
        else
          obj
        end
      end
      
      def self.serialize obj
        obj = inflate(obj)
        str = JSON::generate obj
        [str.length].pack("N") + str
      end
      
      def self.unserialize str
        obj = deflate(JSON::parse str)
        deflate obj
      end
      
      def self.err msg
        $stderr.puts msg
      end
      
      def self.log msg, level = 3
        opts = Flotype::Bridge::options
        if level <= opts['log_level']
          puts msg
        end
      end
      
      def self.cb fun
        ref = LocalRef.new([fun.hash.to_s(36)],
                           Callback.new(fun))
        Core::store(fun.object_id.to_s(36), ref)
        
      end
      
      def self.has_keys? obj, *keys
        keys.each do |k|
          if !obj.has_key?(k)
            return false
          end
        end
        true
      end
      
      def self.local_ref v
        key = v.object_id.to_s(36)
        Core::store key, LocalRef.new([key], v)
      end
    end
  end
end



