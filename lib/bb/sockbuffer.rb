module Bridge

  class SockBuffer
    @buffer = []
    def send msg
      @buffer << msg
    end
    
    def process_queue sock, client_id
      @buffer.each do |msg|
        sock.send( msg.sub '"client",null"', '"client","'+ client_id + '"' )
      end
      @buffer = []
    end
  
  end

end