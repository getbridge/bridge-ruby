require 'uri'
require 'util.rb'
require 'tcp.rb'
require 'serializer.rb'

module Bridge
  class Connection

    attr_accessor :connected, :client_id, :sock
  
    def initialize bridge
      @bridge = bridge

      @options = bridge.options
      
      @sock_buffer = SockBuffer.new
      
      @sock = @sock_buffer
      
      @interval = 0.4
      
      if !@options.has_key? :host or !@options.has_key? :port
        redirector
      else
        EventMachine::connect(@options[:host], @options[:port], Tcp, self)
      end
    end
    
    def redirector
      # Support for redirector.
      uri = URI(@options[:redirector])
      conn = EventMachine::Protocols::HttpClient2.connect(uri.host, uri.port)
      req = conn.get({:uri => "/redirect/#{@options[:api_key]}"})
      req.callback do |obj|
        obj = JSON::parse obj.content
        if obj.has_key?('data')
          obj = obj['data']
          @options[:host] = obj['bridge_host']
          @options[:port] = obj['bridge_port']
          EventMachine::connect(@options[:host], @options[:port], Tcp, self)
        else
          raise Exception, 'Invalid API key.'
        end
      end
    end
    
    def reconnect
      Util.info "Attempting to reconnect"
      if @interval < 32768
        EventMachine::Timer.new(@interval) do
          EventMachine::connect(@options[:host], @options[:port], Tcp, self)
          @interval *= 2
        end
      end
    end
    
    def onmessage data, sock
      # If this is the first message, set our SessionId and Secret.
      m = /^(\w+)\|(\w+)$/.match data[:data]
      if not m
        process_message data
      else
        @client_id = m[1]
        @secret = m[2]
        @interval = 0.4
        @sock = sock
        @sock_buffer.process_queue @sock, @client_id
        Util.info('Handshake complete');
        if not @bridge.is_ready
          @bridge.queue.each { |fun|
            fun.call
          }
          @bridge.queue = []
          @bridge.is_ready = true
        end
      end
    end

    def onopen sock
      Util.info('Beginning handshake');
      msg = Util.stringify(:command => :CONNECT, :data => {:session => [@client_id || nil, @secret || nil], :api_key => @options[:api_key]});
      sock.send msg
    end
    
    def process_message message
      begin
        message = Util.parse(message[:data])
        Util.info "Received #{message}"
        Serializer.unserialize(@bridge, message)
        destination = message['destination']
        if !destination
          Util.warn("No destination in message #{message}")
          return
        end
        @bridge.execute message['destination'].address, message['args']
      rescue Exception => e
        Util.error e.message
      end
    end
    
    def send_command command, data
      data.delete :callback if data.key? :callback and data[:callback].nil?
      msg = Util.stringify :command => command, :data => data
      Util.info('Sending ' + msg)
      @sock.send msg
    end

    def onclose
      Util.warn('Connection closed');
      
      if @sock_buffer
        @sock = @sock_buffer;
      end
      
      if @options[:reconnect]
        reconnect
      end
    end
    
    class SockBuffer
      def initialize
        @buffer = []
      end
      
      def send msg
        @buffer << msg
      end
      
      def process_queue sock, client_id
        @buffer.each do |msg|
          sock.send( msg.sub '"client",null', '"client","'+ client_id + '"' )
        end
        @buffer = []
      end
    end
    
  end
end
