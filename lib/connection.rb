require 'uri'
require 'util.rb'
require 'tcp.rb'
require 'serializer.rb'

module Bridge
  class Connection #:nodoc: all

    attr_accessor :connected, :client_id, :sock, :options
  
    def initialize bridge
      # Set associated bridge object
      @bridge = bridge

      @options = bridge.options
      
      # Preconnect buffer
      @sock_buffer = SockBuffer.new
      @sock = @sock_buffer
      
      # Connection configuration
      @interval = 0.4
    end
    
    # Contact redirector for host and ports
    def redirector
      # Support for redirector.
      uri = URI(@options[:redirector])
      conn = EventMachine::Protocols::HttpClient2.connect(:host => uri.host, :port => uri.port, :ssl => @options[:secure])
      req = conn.get({:uri => "/redirect/#{@options[:api_key]}"})
      req.callback do |obj|
        begin
          obj = JSON::parse obj.content
        rescue Exception => e
          Util.error "Unable to parse redirector response #{obj.content}"
          return
        end
        if obj.has_key?('data') and obj['data'].has_key?('bridge_host') and obj['data'].has_key?('bridge_port')
          obj = obj['data']
          @options[:host] = obj['bridge_host']
          @options[:port] = obj['bridge_port']
          establish_connection
        else
          Util.error "Could not find host and port in JSON body"
        end
      end
    end
    
    def reconnect
      Util.info "Attempting to reconnect"
      if @interval < 32768
        EventMachine::Timer.new(@interval) do
          establish_connection
          # Grow timeout for next reconnect attempt
          @interval *= 2
        end
      end
    end
    
    def establish_connection
      Util.info "Starting TCP connection #{@options[:host]}, #{@options[:port]}"
      EventMachine::connect(@options[:host], @options[:port], Tcp, self)
    end
    
    def onmessage data, sock
      # Parse for client id and secret
      m = /^(\w+)\|(\w+)$/.match data[:data]
      if not m
        # Handle message normally if not a correct CONNECT response
        process_message data
      else
        Util.info "client_id received, #{m[1]}"
        @client_id = m[1]
        @secret = m[2]
        # Reset reconnect interval
        @interval = 0.4
        # Send preconnect queued messages
        @sock_buffer.process_queue sock, @client_id
        # Set connection socket to connected socket
        @sock = sock
        Util.info('Handshake complete')
        # Trigger ready callback
        if not @bridge.is_ready
          @bridge.is_ready = true
          @bridge.emit 'ready'
        end
      end
    end

    def onopen sock
      Util.info 'Beginning handshake' 
      msg = Util.stringify(:command => :CONNECT, :data => {:session => [@client_id || nil, @secret || nil], :api_key => @options[:api_key]})
      sock.send msg
    end
    
    def onclose
      Util.warn 'Connection closed'
      # Restore preconnect buffer as socket connection
      @sock = @sock_buffer
      if @options[:reconnect]
        reconnect
      end
    end
    
    def process_message message
      begin
        Util.info "Received #{message[:data]}"
        message = Util.parse(message[:data])
      rescue Exception => e
        Util.error "Message parsing failed"
      end
      # Convert serialized ref objects to callable references
      Serializer.unserialize(@bridge, message['args'])
      # Extract RPC destination address
      destination = message['destination']
      if !destination
        Util.warn "No destination in message #{message}"
        return
      end
      if message['source']
        @bridge.context = Client.new(@bridge, message['source'])
      end
      @bridge.execute message['destination']['ref'], message['args']
    end
    
    def send_command command, data
      data.delete :callback if data.key? :callback and data[:callback].nil?
      msg = Util.stringify :command => command, :data => data
      Util.info "Sending #{msg}"
      @sock.send msg
    end
    
    def start 
      if !@options.has_key? :host or !@options.has_key? :port
        redirector
      else
        # Host and port are specified
        establish_connection
      end
    end
    
    class SockBuffer
      def initialize
        # Buffer for preconnect messages
        @buffer = []
      end
      
      def send msg
        @buffer << msg
      end
      
      def process_queue sock, client_id
        @buffer.each do |msg|
          # Replace null client ids with actual client_id after handshake
          sock.send( msg.gsub '"client",null', '"client","'+ client_id + '"' )
        end
        @buffer = []
      end
    end
    
  end
end
