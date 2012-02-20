module Bridge
  module Util
    require 'json'
    def self.serialize obj
      # TODO: clone & replace funs with refs.
      obj = JSON::generate obj
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
  end
end
