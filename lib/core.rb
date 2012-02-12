module Bridge
  module Core
    def initialize
      @refs, @queue, @sess = {}, {}, [0, 0]
      @connected, @len = false, 0
    end

    def enqueue fun
      @queue << fun
    end

    def command cmd, data
      Conn::send_data JSON::generate({:command => cmd, :data => data})
    end

    def process data
      if @len == 0
        @len = data.unpack("N")
        return process data[4 .. -1]
      end
      if (@buffer << data).length < @len
        return
      end

      # If this is the first message, set our SessionId and Secret.
      m = /^(\w+)\|(\w+)$/.match data
      if m
        @sess = [m[1], m[2]]
        @queue.each {|fun| fun.call}
        @connected = true
        return
      end
      @buffer, @len = @buffer[@len .. -1], 0
      # Else, it is a normal message.
      unser = Util::unserialize data
      dest = Ref.lookup unser["destination"]
      dest.call *unser["args"]
    end

    def reconnect timeout
      opts = Bridge::options
      if opts[:reconnect]
        EventMachine::connect(opts[:host], opts[:port], Conn)
        EventMachine::Timer.new(timeout) do
          if not @connected
            reconnect timeout*2
          end
        end
      end
    end

    def disconnect
      @connected = false
      reconnect 100
    end
  end
end
