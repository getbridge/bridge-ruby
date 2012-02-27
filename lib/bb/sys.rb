module Bridge
  # These are internal system functions, which should only be called by the
  # Erlang gateway.
  module Sys
    def self.hook_channel_handler name, handler, fun
      fun.call(Core::store(name, Core::lookup(handler), 'channel'))
    end

    def self.remoteError msg
      Util::err(msg)
    end

    def self.get_service name, fun
      fun.call(Core::lookup(name).methods(false))
    end
  end
end
