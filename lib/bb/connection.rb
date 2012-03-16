require 'uri'
require 'bb/util'
require 'bb/sockbuffer'

module Bridge
  class Connection

    def initialize bridge

      @bridge = bridge

      @options = bridge.options
      
      @connected = false
      
      if !@options.has_key? :host or !@options.has_key? :port
        redirector
      else
        EventMachine::connect(@options['host'], @options['port'], @sock = Tcp.new(self))
      end
    end
    
    def redirector
      # Support for redirector.
      uri = URI(@options.redirector)
      conn = EventMachine::Protocols::HttpClient2.connect(uri.host, uri.port)
      req = conn.get({:uri => "/redirect/#{@options['api_key']}"})
      req.callback do |obj|
        obj = JSON::parse obj.content
        if obj.has_key?('data')
          obj = obj['data']
          @options[:host] = obj['bridge_host']
          @options[:port] = obj['bridge_port']
          EventMachine::connect(@options[:host], @options[:port], @sock = Tcp.new(self))
        else
          raise Exception, 'Invalid API key.'
        end
      end
    end
    
    def reconnect
      Util.info "Attempting to reconnect"
      if not @connected and @interval < 12800
        EventMachine::Timer.new(timeout) do
          EventMachine::connect(@options[:host], @options[:port], @sock = Tcp.new(self))
          @interval *= 2
        end
      end
    end
    
    def onmessage data
      Util.info("clientId and secret received #{data[:data]}");
      # If this is the first message, set our SessionId and Secret.
      m = /^(\w+)\|(\w+)$/.match data[:data]
      if not m
        process_message data
      else
        @connected = true
        @client_id = m[1]
        @secret = m[2]
        @interval = 400
        @sock_buffer.process_queue @sock, @client_id
        Util.info('Handshake complete');
        if !@bridge.ready
          @bridge.queue.each { |fun|
            fun.call
          }
          @bridge.queue = []
          @bridge.ready = true
        end
      end
    end

    def onopen
      util.info('Beginning handshake');
      var msg = Util.stringify(command => :CONNECT, data => {session: [@client_id || nil, @secret || nil], api_key: @options.api_key});
      @sock.send msg
    end
    
    def process_message message
      message = Util.parse(message[:data])
      Util.info "Received #{message}"
      Util.unserialize(@bridge, message)
      destination = message[:destination]
      if !destination
        Util.warn("No destination in message #{message}")
        return
      end
      @bridge.execute message.destination.address, message.args
    end
    
    def sendCommand command, data
      msg = Util.stringify command => command, data => data
      Util.info "Sending #{msg}"
      @sock.send msg
    end

    def onclose
      Util.warn('Connection closed');
      
      if @sock_buffer
        @sock = @sock_buffer;
      end
      
      @connected = false;
      if @options.reconnect
        reconnect
      end
    end
    
    
  end
end
