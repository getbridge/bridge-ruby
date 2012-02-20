module Bridge
  module Sys
    def self.hook_channel_handler name, handler, fun
      fun.call(Core::store(name, Core::lookup(handler), false))
    end

    def self.remote_error msg
      Util::err(msg)
    end

    def self.get_service name, fun
      fun.call(Core::lookup(name).methods(false))
    end
  end
end
