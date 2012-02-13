module Bridge
  module Conn
    def self.send *args
      @@conn.send_data *args
    end

    # Methods expected by EventMachine.
    def initialize
      @@conn = self
      @buffer = ""
    end

    def post_init
      Core::command(:CONNECT,
                    { :session => Core::session,
                      :api_key => Bridge::options[:api_key] })
    end

    def receive_data data
      @buffer = Core::process(@buffer << data)
    end

    def unbind
      Core::disconnect
    end
  end
end
