module Bridge
  # The internals of the Bridge client. Use of this module is strongly
  # unadvised, as the internal structure may vary greatly from that of
  # other language implementations.
  module Core
    @@services, @@refs, @@queue = {'system' => Bridge::Sys}, {}, []
    @@connected, @@len, @@buffer, @@sess = false, 0, '', [0, 0]

    def self.session
      @@sess
    end

    def self.client_id
      @@sess[0]
    end

     def self.connected
      @@connected
    end

    # The queue is used primarily for Bridge::ready() callbacks.
    def self.enqueue fun
      if @@connected
        fun.call
        Util::log 'Already connected.'
      else
        Util::log 'enqueuing function'
        @@queue << fun
      end
    end

    def self.store svc, obj = {}, named = true
      @@services[[named ? svc : 'channel:' + svc].to_json] = obj
    end

    def self.lookup ref
      ref = JSON::parse ref.to_json
      svc = @@services[ref[2]]
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
        Util::log 'Received secret and session ID: ' + @@sess.to_json
        @@queue.each {|fun| fun.call}
        @@queue = []
        @@connected = true
        return
      end
      @@buffer, @@len = @@buffer[@@len .. -1], 0
      # Else, it is a normal message.
      unser = Util::unserialize data
      dest = unser['destination']
      if dest.respond_to? :call
        dest.call *unser['args']
      else
        dest = lookup dest
      end
    end

    def self.command cmd, data
      if cmd == :CONNECT
        Conn::send(Util::serialize({:command => cmd, :data => data}))
      else 
        Core::enqueue lambda {
          Conn::send(Util::serialize({:command => cmd, :data => data}))
        }
      end
    end

    def self.reconnect timeout
      Util::log 'Attempting to reconnect; waiting at most ' + timeout + 's.'
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
