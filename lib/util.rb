module Bridge
  module Util
    require 'json'
    def serialize obj
      obj = JSON::parse obj
      [obj.length].pack("N") + obj
    end

    def unserialize str
      obj = JSON::generate str.gsub('{"ref":', '{"json_class":"Ref","ref":')
    end
  end
end
