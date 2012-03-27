require 'eventmachine'

module Bridge
  class Tcp < EventMachine::Connection #:nodoc: all
  
    def initialize connection
      @buffer = ''
      @len = 0
      @pos = 0
      @callback = nil
      @connection = connection
      start
    end
    
    def post_init
      @connection.onopen self
    end

    def receive_data data
      left = @len - @pos
      if data.length >= left
        @buffer << data.slice(0, left)
        @callback.call @buffer
        receive_data data.slice(left..-1) unless data.nil?
      else
        @buffer << data
        @pos = @pos + data.length
      end
    end
    
    def read len, &cb
      @buffer = ''
      @len = len
      @pos = 0
      @callback = cb
    end
    
    def start
      read 4 do |data|
        read data.unpack('N')[0] do |data|
          @connection.onmessage({:data => data}, self)
          start
        end
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
