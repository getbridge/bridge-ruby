require 'util.rb'
require 'serializer.rb'
require 'connection.rb'
require 'reference.rb'
require 'client.rb'

require 'eventmachine'

# == Flotype Bridge
#
# Bridge is a cross-language and platform framework for realtime
# communication and RPC.
#
# The Bridge ruby client is fully featured and has full compatibility with
# all other Bridge clients.
# 
# Bridge::Bridge

module Bridge

  @@instance = nil

  def self.instance
    @@instance
  end

  def self.instance= i
    @@instance = i
  end


  class Bridge

    attr_accessor :context, :options, :connection, :store, :is_ready #:nodoc:
    
    # :call-seq:
    #   new(options={})
    #
    # Create an instance of the Bridge object. This object will be used for
    # Bridge interactions.
    #  
    # Bridge#connect must be called to connect to the Bridge server.
    #
    # === Attributes  
    #  
    # +options+:: Optional hash of arguments specified below.
    #  
    # === Options  
    #  
    # Options hash passed to initialize to modify Bridge behavior.
    #  
    # <tt>:redirector => 'http://redirector.flotype.com'</tt>:: Address to
    #   specify Bridge redirector server. The redirector server helps route
    #   the client to the appropriate Bridge server,

    # <tt>:reconnect => true</tt>:: Enable automatic reconnection to Bridge
    #   server.

    # <tt>:log => 2</tt>:: An integer specifying log level. 3 => Log all,
    #   2 => Log warnings, 1 => Log errors, 0 => No logging output.

    # <tt>:host => nil</tt>:: The hostname of the Bridge server to connect
    #   to. Overrides +:redirector+ when both +:host+ and +:port+ are
    #   specified,

    # <tt>:port => nil</tt>:: An integer specifying the port of the Bridge
    #   server to connect to. Overrides +:redirector+ when both +:host+ and
    #   +:port+ are specified.
    def initialize(options = {})

      # Set default options
      @options = {
        :redirector => 'http://redirector.flotype.com',
        :secure_redirector => 'https://redirector.flotype.com',
        :secure => false,
        :reconnect  => true,
        :log  => 2, # 0 for no output
      }

      @options = @options.merge(options)

      if @options[:secure]
        @options[:redirector] = @options[:secure_redirector]
      end
  
      Util.set_log_level(@options[:log])
  
      @store = {}
      # Initialize system service call
      @store['system'] = SystemService.new(self)
      
      # Indicates whether server is connected and handshaken
      @is_ready = false
      
      # Create connection object
      @connection = Connection.new(self)
      
      # Store event handlers
      @events = {}

      @context = nil
    end

    def execute address, args #:nodoc:
      # Retrieve stored handler
      obj = @store[address[2]]
      # Retrieve function in handler
      func = obj.method(address[3])
      if func
        last = args.last
        # If last argument is callable and function arity is one less than
        #   args length, pass in as block
        if (last.is_a? Proc) and func.arity == args.length - 1
          args.pop
          func.call *args do |*args, &blk|
            args << blk if blk
            last.call *args
          end
        else
          begin
            func.call *args
          rescue StandardError => err
            Util.error err
            Util.error "Exception while calling #{address[3]}(#{args})"
          end
        end
      else
        Util.warn "Could not find object to handle, #{address}"
      end
    end
    
    def store_object handler, ops #:nodoc:
      # Generate random id for callback being stored
      name = Util.generate_guid
      @store[name] = handler
      # Return reference to stored callback
      Reference.new(self, ['client', @connection.client_id, name], ops)
    end
    
    # :call-seq:
    #   on(name) { |*args| block }
    #
    # Adds the given block as a handler for the event specified by
    #   <tt>name</tt>. Calling multiple times will result in multiple
    #   handlers being attached to the event
    #  
    # === Attributes  
    #  
    # +name+:: The name of the event for the given block to listen to
    #
    # === Events  
    #  
    # List of events Bridge emits
    #  
    # <tt>'ready' ()</tt>:: Bridge is connected and ready. Not emitted on
    #   reconnects
    # <tt>'remoteError' (error_message)</tt>:: A remote error has occurred
    #   in Bridge. The error message is provided as a parameter
    def on name, &fn
      if !@events.key? name
        @events[name] = [];
      end
      @events[name] << fn
    end
    
    def emit name, args=[] #:nodoc:
      if @events.key? name
        @events[name].each do |fn|
          fn.call *args
        end
      end
    end
    
    def send args, destination #:nodoc:
      @connection.send_command(:SEND,
                               { :args => Serializer.serialize(self, args),
                                 :destination => destination })
    end

    # :call-seq:
    #   publish_service(name, handler) { |name| block }
    #
    # Publishes a ruby object or module as a Bridge service with the given
    #   name.
    #
    # If a block is given, calls the given block with the name of the
    #   published service upon publish success
    #  
    # === Attributes  
    #  
    # +name+:: The name of the Bridge service the handler will be published
    #   with
    # +handler+:: A ruby object or module to publish
    #  
    def publish_service name, handler, &callback
      if name == 'system'
        Util.error("Invalid service name: #{name}")
      else
        @store[name] = handler
        @connection.send_command(
          :JOINWORKERPOOL,
          { :name => name,
            :callback => Serializer.serialize(self, callback)}
        )
      end
    end

    # :call-seq:
    #   unpublish_service(name, handler) { |name| block }
    #
    # Stops publishing a ruby object or module as a Bridge service with the
    #   given name.
    #
    # If a block is given, calls the given block with the name of the
    #   unpublished service.
    #  
    # === Attributes  
    #  
    # +name+:: The name of the Bridge service that will no longer be
    #   published
    #  
    def unpublish_service name, &callback
      if name == 'system'
        Util.error("Invalid service name: #{name}")
      else
        @connection.send_command(
          :LEAVEWORKERPOOL,
          { :name => name,
            :callback => Serializer.serialize(self, callback)}
        )
      end
    end
    
    # :call-seq:
    #   get_service(name) -> service
    #   get_service(name) { |service, name| block }
    #
    # Retrives a service published to Bridge with the given name.
    #
    # If multiple Bridge clients have a published a service, the service is
    #   retrieved from one of the publishers round-robin.
    #
    # Note that if the requested service does not exist, an object is still
    #   returned, however attempts to make method calls on the object will
    #   result in a remote error.
    #
    # Returns the requested service.
    #
    # If a block is given, calls the given block with the requested service
    #   and service name.
    #  
    # === Attributes  
    #  
    # +name+:: The name of the Bridge service being requested
    #  
    def get_service name, &callback
      ref = Reference.new(self, ['named', name, name])
      callback.call(ref, name) if callback
      return ref
    end

    def get_client id
      return Client.new(self, id)
    end

    # :call-seq:
    #   get_channel(name) -> channel
    #   get_channel(name) { |channel, name| block }
    #
    # Retrives a channel from Bridge with the given name.
    #
    # Calling a method on the channel object will result in the given
    #   method being executed on all clients that have been joined to the
    #   channel.
    #
    # Note that if the requested channel does not exist or is empty, an
    #   object is still returned, however attempts to make method calls on
    #   the object will result in a remote error.
    #
    # Returns the requested channel.
    #
    # If a block is given, calls the given block with the requested channel
    #   and channel name.
    #  
    # === Attributes  
    #  
    # +name+:: The name of the Bridge channel being requested
    #  
    def get_channel name, &callback
      # Send GETCHANNEL command in order to establih link for channel if
      #   client is not member
      @connection.send_command(:GETCHANNEL, {:name => name})
      ref = Reference.new(self, ['channel', name, "channel:#{name}"])
      callback.call(ref, name) if callback
      return ref
    end
    
    # :call-seq:
    #   join_channel(name, handler) { |channel, name| block }
    #
    # Provides a remote object, ruby object or module as a receiver for
    #   methods calls on a Bridge channel.
    #    
    # The given handler can be a remote object, in which case the Bridge
    #   client that created the remote object will be joined to the
    #   channel. Method calls to the channel will be not be proxied through
    #   this client but go directly to the source of the remote object.
    #
    # If a block is given, calls the given block with the joined channel
    #   and channel name.
    # 
    # === Attributes  
    #  
    # +name+:: The name of the Bridge channel the handler will recieve
    #   methods calls for.

    # +handler+:: A remote object, ruby object or module to handle method
    #   calls from the channel
    def join_channel name, handler, &callback
      @connection.send_command(
        :JOINCHANNEL,
        { :name => name,
          :handler => Serializer.serialize(self, handler),
          :callback => Serializer.serialize(self, callback)}
      )
    end

    # :call-seq:
    #   leave_channel(name, handler)
    #   leave_channel(name, handler) { |name| block }
    #
    # Leaves a Bridge channel with the given name and handler object.
    #    
    # The given handler can be a remote object, in which case the Bridge
    #   client that created the remote object will be removed from the
    #   channel.
    #
    # If a block is given, calls the given block with the name of the
    #   channel left.
    # 
    # === Attributes  
    #  
    # +name+:: The name of the Bridge channel to leave
    # +handler+:: A remote object, ruby object or module that was used to
    #   handle moethod calls from the channel
    #  
    def leave_channel channel, handler, &callback
      @connection.send_command(
        :LEAVECHANNEL,
        { :name => name,
          :handler => Serializer.serialize(self, handler),
        :callback => Serializer.serialize(self, callback)}
      )
    end
    
    # :call-seq:
    #   ready { block }
    #
    # Calls the given block when Bridge is connected and ready.
    # Calls the given block immediately if Bridge is already ready.
    # 
    def ready &callback
      if @is_ready
        callback.call
      else
        on 'ready', &callback
      end
    end
    
    # :call-seq:
    #   connect { block }
    #
    # Starts the connection to the Bridge server.
    #
    # If a block is given, calls the given block when Bridge is connected
    #   and ready.
    #
    def connect &callback
      self.ready &callback if callback
      @connection.start
      return self
    end

    # These are internal system functions, which should only be called by
    # the Erlang gateway.
    class SystemService #:nodoc:
      def initialize bridge
        @bridge = bridge
      end
      
      def hookChannelHandler name, handler, callback = nil
        # Store under channel name
        @bridge.store["channel:#{name}"] = handler
        # Send callback with reference to channel and handler operations
        callback.call(Reference.new(self,
                                    ['channel', name, "channel:#{name}"],
                                    Util.find_ops(handler)), name) if callback
      end

      def getService name, callback
        if @bridge.store.key? name
          callback.call(@bridge.store[name], name)
        else
          callback.call(nil, name)
        end
      end
      
      def remoteError msg
        Util.warn msg
        @bridge.emit 'remote_error', [msg]
      end 
    end
        
  
  end
  
end
