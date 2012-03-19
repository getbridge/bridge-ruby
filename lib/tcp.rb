require 'eventmachine'

module Bridge
  class Tcp < EventMachine::Connection #:nodoc: all
  
    def initialize connection
      @left = 0
      @chunk = ''
      @head_chunk = ''
      @connection = connection
    end
    
    def post_init
      @connection.onopen self
    end

    def receive_data data
      if @left == 0
        data = @head_chunk + data
        if data.length >= 4
          @left = data.unpack('N')[0]
          data = data[4 .. -1]
          @chunk = ''
          @head_chunk = ''
        else
          @head_chunk = data
          return
        end
      end

      if data.length == 0
        return
      elsif data.length < @left
        @chunk << data
        @left -= data.length
      elsif data.length == @left
        @chunk << data
        @connection.onmessage({:data => @chunk}, self)
        @left = 0
      elsif data.length > @left
        @chunk << data[0 ... @left]
        @connection.onmessage({:data => @chunk}, self)
        data = data[@left .. -1]
        @left = 0
        receive_data data
      end
    end

    def send arg
      send_data([arg.length].pack("N") + arg)
    end
    
    def unbind
      @connection.onclose
    end
    
  end  
end
