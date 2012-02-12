module Bridge
  module Conn
    # Methods expected by EventMachine.
    def post_init
      Core::command(:CONNECT,
                    { :session => @sess,
                      :api_key => @options[:api_key] })
    end

    def receive_data data
      @buffer = Core::process(@buffer << data)
    end

    def unbind
      Core::disconnect
    end
  end
end
