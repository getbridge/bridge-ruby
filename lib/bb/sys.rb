module Bridge
  # These are internal system functions, which should only be called by the
  # Erlang gateway.
  module Sys
    def self.hook_channel_handler name, handler, fun = false
      ref = Core::store(name, Core::lookup(handler), false)
      if fun then
        fun.call(ref, name)
      end
    end

    def self.remote_error msg
      Util::err(msg)
    end

    def self.get_service name, fun
      fun.call(Core::lookup(name).methods(false))
    end
  end
end
