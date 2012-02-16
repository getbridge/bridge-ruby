module Bridge
  module Sys
    def hookChannelHandler name, handler, fun
      fun(Core::store(name, Core::lookup(handler), false))
    end

    def remoteError msg
      Util::err(msg)
    end

    def getService name, fun
      fun(Core::lookup(name).methods(false))
    end
  end
end
