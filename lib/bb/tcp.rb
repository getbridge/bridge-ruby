module Bridge
  class Tcp
    def initialize bridge
      @left = 0
      @chunk = ''
      @connection = bridge.connection
    end
    
    def send arg
      send_data([str.length].pack("N") + arg)
    end

    module EventMachineCallback
    
      def post_init
        @connection.onopen
      end

      def receive_data data
        if @left == 0
          @left = data.unpack('N')[0]
          data = data[4 .. -1]
          @chunk = ''
        end

        if data.length < @left
          @chunk << data
          @left -= data.length
        elsif data.length == @left
          @chunk << data
          @connection.onmessage data => @chunk
          @left = 0
        elsif data.length > @left
          chunk << data[0 ... @left]
          @connection.onmessage data => @chunk
          data = data[@left .. -1]
          @left = 0
          receive_data data
        end
      end

      def unbind
        @connection.onclose
      end
    
    end
    
  end
  
end
