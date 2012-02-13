module Bridge
  module Core
    @@services, @@refs, @@queue, @@sess = {}, {}, [], [0, 0]
    @@connected, @@len, @@buffer = false, 0, ''

    def self.session
      @@sess
    end

    # The queue is used solely for Bridge::ready() callbacks.
    def self.enqueue fun
      @@queue << fun
    end

    def self.store svc, obj = {}, named = true
      @@services[[named ? 'named' : 'channel', svc,
                  named ? svc : 'channel:' + channel]] = obj
    end

    def self.lookup ref
      ref = ref.path
      svc = @@services[ref[0 .. 2]]
      if svc != nil && svc.respond_to?(ref[3])
        return svc.method ref[3]
      end
      Ref.lookup ref
    end

    def self.process data
      if @@len == 0
        @@len = data.unpack('N')[0]
        return process data[4 .. -1]
      end
      (@@buffer << data)
      if @@buffer.length < @@len
        return
      end

      # If this is the first message, set our SessionId and Secret.
      m = /^(\w+)\|(\w+)$/.match data
      if m
        @@sess = [m[1], m[2]]
        @@queue.each {|fun| fun.call}
        @@connected = true
        return
      end
      @@buffer, @@len = @@buffer[@@len .. -1], 0
      # Else, it is a normal message.
      unser = Util::unserialize data
      dest = lookup unser['destination']
      dest.call *unser['args']
    end

    def self.command cmd, data
      Conn::send Util::serialize({:command => cmd, :data => data})
    end

    def self.reconnect timeout
      opts = Bridge::options
      if opts[:reconnect]
        EventMachine::connect(opts[:host], opts[:port], Conn)
        EventMachine::Timer.new(timeout) do
          if not @@connected
            reconnect timeout*2
          end
        end
      end
    end

    def self.disconnect
      @@connected = false
      reconnect 100
    end
  end
end
