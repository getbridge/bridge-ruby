module Bridge
  module Conn
    def self.send arg, force = false
      @@conn.send_data arg
    end

    # Methods expected by EventMachine.
    def initialize
      Util::log 'Connection initialized.'
      @@conn = self
    end

    def post_init
      Util::log 'Starting handshake.'
      Core::command(:CONNECT,
                    { :session => Core::session,
                      :api_key => Bridge::options[:api_key] })
    end

    def receive_data data
      Util::log 'Got data.'
      Core::process(data)
    end

    def unbind
      Util::log 'Disconnected.'
      Core::disconnect
    end
  end
end
