module Bridge
  module Util
    require 'json'
    def self.serialize obj
      # TODO: clone & replace funs with refs.
      obj = JSON::generate obj
      [obj.length].pack("N") + obj
    end

    def self.unserialize str
      obj = JSON::parse str.gsub('{"ref":', '{"json_class":"Ref","ref":')
    end

    def err msg
      $stderr.puts err
    end

    def log msg
      puts err
    end
  end
end
