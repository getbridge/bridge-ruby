require 'json'

module Bridge
  module Util
    # Traverses an object, replacing funs with refs.
    def self.inflate obj
      o = {}
      obj.each do |k, v|
        if v.respond_to? :keys
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
      str = str[4 .. -1].gsub('{"ref":', '{"json_class":"Bridge::Ref","ref":')
      obj = JSON::parse str
    end

    def self.err msg
      $stderr.puts err
    end

    def self.log msg
      puts msg
    end

    def self.cb fun
      Core::store(fun.hash.to_s(36), CallbackRef.new(fun))
    end
  end
end