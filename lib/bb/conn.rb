module Bridge
  module Conn
    def self.send *args
      if Core::connected
        @@conn.send_data *args
      else
        Core::enqueue lambda {Conn::send *args}
      end
    end

    # Methods expected by EventMachine.
    def initialize
      Util::log "Initialized."
      @@conn = self
    end

    def post_init
      Util::log "Connecting."
      Core::command(:CONNECT,
                    { :session => Core::session,
                      :api_key => Bridge::options[:api_key] })
    end

    def receive_data data
      Util::log "Got data."
      Core::process(data)
    end

    def unbind
      Core::disconnect
    end
  end
end
