module Bridge
  module Sys
    def hook_channel_handler name, handler, fun
      fun(Core::store(name, Core::lookup(handler), false))
    end

    def remote_error msg
      Util::err(msg)
    end

    def get_service name, fun
      fun(Core::lookup(name).methods(false))
    end
  end
end
