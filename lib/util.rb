module Bridge
  module Util
    require 'json'
    def self.serialize obj
      obj = JSON::generate obj
      [obj.length].pack("N") + obj
    end

    def self.unserialize str
      obj = JSON::parse str.gsub('{"ref":', '{"json_class":"Ref","ref":')
    end
  end
end
