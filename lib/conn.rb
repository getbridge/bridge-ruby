module Bridge
  module Conn
    # Methods expected by EventMachine.
    def post_init
      Core::command(:connect,
                    { :session => @sess,
                      :api_key => @options[:api_key] })
    end
    
    def receive_data data
      @buffer = process(@buffer << data)
    end
    
    def unbind
      Core::disconnect
    end
  end
end
