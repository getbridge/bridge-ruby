module Bridge
  module Util
    require 'json'
    def serialize obj
      obj = JSON::parse(obj)
      [obj.length].pack("N") + obj
    end

    def inflate obj
      if obj.respond_to? :keys
        obj.each do |x|
          obj[x] = inflate obj[x]
        end
      end
      obj["ref"] ? (Core::lookup obj["ref"]) : obj
    end

    def unserialize str
      obj = str.to_json
      revive obj
    end

  end
end
