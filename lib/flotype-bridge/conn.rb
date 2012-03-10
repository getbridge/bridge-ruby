module Flotype
  module Bridge
    module Conn
      def self.send arg
        Util::log 'sending: ' + arg
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
                        :api_key => Flotype::Bridge::options['api_key'] })
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
end
