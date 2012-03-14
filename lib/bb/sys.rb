module Bridge
  # These are internal system functions, which should only be called by the
  # Erlang gateway.
  module Sys
    def self.hook_channel_handler name, handler, fun
      fun.call(Core::store('channel:' + name, handler), name)
    end

    def self.remoteError msg
      Util::err(msg)
    end

    def self.getservice name, fun
      fun.call(Core::get(name))
    end
  end
end
