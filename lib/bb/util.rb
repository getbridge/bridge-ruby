require 'json'

module Bridge
  module Util
    # Traverses an object, replacing funs with refs.
    def self.inflate obj
      o = {}
      obj.each do |k, v|
        if v.respond_to?(:keys) && !v.respond_to?(:call)
          o[k] = inflate v
        else
          o[k] = (v.respond_to?(:call) && !v.respond_to?(:path)) ? cb(v) : v
        end
      end
      o
    end

    def self.serialize obj
      # TODO: clone & replace funs with refs.
      obj = JSON::generate inflate(obj)
      [obj.length].pack("N") + obj
    end

    def self.unserialize str
      str = str.gsub('{"ref":', '{"json_class":"Bridge::Ref","ref":')
      JSON::parse str
    end

    def self.err msg
      $stderr.puts err
    end

    def self.log msg, level = 3
      if level <= Bridge::options['log_level']
      puts msg
    end

    def self.cb fun
      ref = CallbackRef.new(fun)
      Core::store(fun.hash.to_s(36), ref)
      ref
    end

    def self.has_keys? obj, *keys
      keys.each do |k|
        if !obj.has_key?(k) && !obj.has_key?(k.to_sym)
          return false
        end
      end
      true
    end
  end
end
