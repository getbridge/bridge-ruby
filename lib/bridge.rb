require 'connection.rb'
require 'reference.rb'
require 'util.rb'
require 'serializer.rb'

require 'eventmachine'

module Bridge
  class Bridge
    # Expects to be called inside an EventMachine block in lieu of
    #   EM::connect.
    # @param [Hash] configuration options

    attr_accessor :options, :connection, :queue, :store, :is_ready
    
    def initialize(options = {}, &callback)

      @options = {
        :redirector => 'http://redirector.flotype.com',
        :reconnect  => true,
        :log  => 2, # 0 for no output.
      }    
    
      @options = @options.merge(options)
  
      @store = {}
      @store['system'] = SystemService.new(self)
      
      @is_ready = false
      
      @connection = Connection.new(self)
      
      @queue = []

      self.ready &callback if callback
      
    end

    def execute address, args
      obj = @store[address[2]]
      # TODO: make blocks + procs
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
    
    def store_object handler, ops
      name = Util.generateGuid
      @store[name] = handler
      Reference.new(self, ['client', @connection.client_id, name], ops)
    end
    


    # Calls a remote function specified by `dest` with `args`.
    # @param [Ref] dest The identifier of the remote function to call.
    # @param [Array] args Arguments to be passed to `dest`.
    def send args, destination
      @connection.send_command(:SEND, { :args => Serializer.serialize(self, args), :destination => destination })
    end

    # Broadcasts the availability of certain functionality specified by a
    #   proc `fun` under the name of `name`.
    def publish_service name, handler, &callback
      if name == 'system'
        Util::error("Invalid service name: #{name}")
      else
        @store[name] = handler
        @connection.send_command(:JOINWORKERPOOL, {:name => name, :callback => Serializer.serialize(self, callback)})
      end
    end

    # Returns a reference to the service specified by `svc`.
    def get_service name, &callback
      ref = Reference.new(self, ['named', name, name])
      callback.call(ref, name) if callback
      return ref
    end

    # Returns a reference to the channel specified by `channel`.
    def get_channel name, &callback
      @connection.send_command(:GETCHANNEL, {:name => name})
      ref = Reference.new(self, ['channel', name, "channel:#{name}"])
      callback.call(ref, name) if callback
      return ref
    end
    
    # Join the channel specified by `channel`. Messages from this channel
    #   will be passed in to a handler specified by `handler`. The callback
    #   `callback` is to be called to confirm successful joining of the channel.
    def join_channel name, handler, &callback
      @connection.send_command(:JOINCHANNEL, {:name => name, :handler => Serializer.serialize(self, handler), :callback => Serializer.serialize(self, callback)})
    end

    # Leave a channel.
    def leave_channel channel, handler, &callback
      @connection.send_command(:LEAVECHANNEL, {:name => name, :handler => Serializer.serialize(self, handler), :callback => Serializer.serialize(self, callback)})
    end
    
    # Similar to $(document).ready of jQuery as well as now.ready: takes
    #   callbacks that it will call when the connection handshake has been
    #   completed.
    # @param [#call] callback Callback to be called when the server connects.
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
    class SystemService
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
        Util::warn(msg)
      end
    end
        
  
  end
  
end
