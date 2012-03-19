require 'util.rb'
require 'serializer.rb'
require 'connection.rb'
require 'reference.rb'

require 'eventmachine'

# == Flotype Bridge
#
# Bridge is a cross-language and platform framework for realtime communication and RPC
#
# The Bridge ruby client is fully featured and has full compatibility with all other Bridge clients
# 
# Bridge::Bridge

module Bridge

  class Bridge

    attr_accessor :options, :connection, :queue, :store, :is_ready #:nodoc: 
    
    # :call-seq:
    #   new(options={})
    #   new(options={}) { block } 
    #
    # Create an instance of the Bridge object. This object will be used for Bridge interactions
    #  
    # If a block is given, calls the given block when Bridge is connected and ready for use 
    #
    # === Attributes  
    #  
    # +options+:: Optional hash of arguments specified below
    #  
    # === Options  
    #  
    # Options hash passed to initialize to modify Bridge behavior
    #  
    # <tt>:redirector => 'http://redirector.flotype.com'</tt>:: Address to specify Bridge redirector server. The redirector server helps route the client to the appropriate Bridge server 
    # <tt>:reconnect => true</tt>:: Enable automatic reconnection to Bridge server
    # <tt>:log => 2</tt>:: An integer specifying log level. 3 => Log all, 2 => Log warnings, 1 => Log errors, 0 => No logging output
    # <tt>:host => nil</tt>:: The hostname of the Bridge server to connect to. Overrides +:redirector+ when both +:host+ and +:port+ are specified
    # <tt>:port => nil</tt>:: An integer specifying the port of the Bridge server to connect to. Overrides +:redirector+ when both +:host+ and +:port+ are specified
    #  
    def initialize(options = {}, &callback)

      @options = {
        :redirector => 'http://redirector.flotype.com',
        :reconnect  => true,
        :log  => 2, # 0 for no output
      }    
    
      @options = @options.merge(options)
  
      Util.set_log_level(@options[:log]);
  
      @store = {}
      @store['system'] = SystemService.new(self)
      
      @is_ready = false
      
      @connection = Connection.new(self)
      
      @queue = []

      self.ready &callback if callback
      
    end

    def execute address, args #:nodoc:
      obj = @store[address[2]]
      func = obj.method(address[3])
      if func
        last = args.last
        if last.is_a? Util::CallbackReference and func.arity == args.length - 1
          args.pop
          func.call *args do |*args, &blk|
            args << blk if blk
            last.call *args
          end
        else
          func.call *args
        end
      else
        Util.warn 'Could not find object to handle', address
      end
    end
    
    def store_object handler, ops #:nodoc:
      name = Util.generate_guid
      @store[name] = handler
      Reference.new(self, ['client', @connection.client_id, name], ops)
    end
    
    def send args, destination #:nodoc:
      @connection.send_command(:SEND, { :args => Serializer.serialize(self, args), :destination => destination })
    end

    # :call-seq:
    #   publish_service(name, handler) -> service
    #   publish_service(name, handler) { |service, name| block }
    #
    # Publishes a ruby object or module as a Bridge service with the given name.
    #    
    # Returns the published service.
    #
    # If a block is given, calls the given block with the published service and service name.
    #  
    # === Attributes  
    #  
    # +name+:: The name of the Bridge service the handler will be published with
    # +handler+:: A ruby object or module to publish
    #  
    def publish_service name, handler, &callback
      if name == 'system'
        Util.error("Invalid service name: #{name}")
      else
        @store[name] = handler
        @connection.send_command(:JOINWORKERPOOL, {:name => name, :callback => Serializer.serialize(self, callback)})
      end
    end

    # :call-seq:
    #   get_service(name) -> service
    #   get_service(name) { |service, name| block }
    #
    # Retrives a service published to Bridge with the given name.
    #
    # If multiple Bridge clients have a published a service, the service is retrieved from one of the publishers round-robin.
    #
    # Note that if the requested service does not exist, an object is still returned, however attempts to make method calls on the object will result in a remote error.
    #
    # Returns the requested service.
    #
    # If a block is given, calls the given block with the requested service and service name.
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

    # :call-seq:
    #   get_channel(name) -> channel
    #   get_channel(name) { |channel, name| block }
    #
    # Retrives a channel from Bridge with the given name.
    #
    # Calling a method on the channel object will result in the given method being executed on all clients that have been joined to the channel.
    #
    # Note that if the requested channel does not exist or is empty, an object is still returned, however attempts to make method calls on the object will result in a remote error.
    #
    # Returns the requested channel.
    #
    # If a block is given, calls the given block with the requested channel and channel name.
    #  
    # === Attributes  
    #  
    # +name+:: The name of the Bridge channel being requested
    #  
    def get_channel name, &callback
      @connection.send_command(:GETCHANNEL, {:name => name})
      ref = Reference.new(self, ['channel', name, "channel:#{name}"])
      callback.call(ref, name) if callback
      return ref
    end
    
    # :call-seq:
    #   join_channel(name, handler) { |channel, name| block }
    #
    # Provides a remote object, ruby object or module as a receiver for methods calls on a Bridge channel.
    #    
    # The given handler can be a remote object, in which case the Bridge client that created the remote object will be joined to the channel. Method calls to the channel will be not be proxied through this client but go directly to the source of the remote object.
    #
    # If a block is given, calls the given block with the joined channel and channel name.
    # 
    # === Attributes  
    #  
    # +name+:: The name of the Bridge channel the handler will recieve methods calls for
    # +handler+:: A remote object, ruby object or module to handle method calls from the channel
    #  
    def join_channel name, handler, &callback
      @connection.send_command(:JOINCHANNEL, {:name => name, :handler => Serializer.serialize(self, handler), :callback => Serializer.serialize(self, callback)})
    end

    # :call-seq:
    #   leave_channel(name, handler)
    #   leave_channel(name, handler) { |name| block }
    #
    # Leaves a Bridge channel with the given name and handler object.
    #    
    # The given handler can be a remote object, in which case the Bridge client that created the remote object will be removed from the channel.
    #
    # If a block is given, calls the given block with the name of the channel left.
    # 
    # === Attributes  
    #  
    # +name+:: The name of the Bridge channel to leave
    # +handler+:: A remote object, ruby object or module that was used to handle moethod calls from the channel
    #  
    def leave_channel channel, handler, &callback
      @connection.send_command(:LEAVECHANNEL, {:name => name, :handler => Serializer.serialize(self, handler), :callback => Serializer.serialize(self, callback)})
    end
    
    # :call-seq:
    #   ready { block }
    #
    # Calls the given block when Bridge is connected and ready.
    # Calls the given block immediately if Bridge is already ready.
    # 
    def ready &callback
      puts 'adding'
      if @is_ready
        callback.call
      else
        @queue << callback
      end
    end

    # These are internal system functions, which should only be called by the
    # Erlang gateway.
    class SystemService #:nodoc:
      def initialize bridge
        @store = bridge.store
      end
      
      def hookChannelHandler name, handler, callback = nil
        obj = @store[handler.address[2]]
        @store["channel:#{name}"] = obj
        callback.call(Reference.new(self, ['channel', name, "channel:#{name}"], obj.methods), name) if callback
      end

      def getService name, callback
        if @store.key? name
          callback.call(@store[name], name)
        else
          callback.call(nil, name)
        end
      end
      
      def remoteError msg
        Util.warn(msg)
      end
    end
        
  
  end
  
end
