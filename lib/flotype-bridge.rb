require 'flotype-bridge/svc'
require 'flotype-bridge/conn'
require 'flotype-bridge/ref'
require 'flotype-bridge/sys'
require 'flotype-bridge/core'
require 'flotype-bridge/localref'
require 'flotype-bridge/callback'
require 'flotype-bridge/util'

require 'eventmachine'

module Flotype
  module Bridge

    # Expects to be called inside an EventMachine block in lieu of
    #   EM::connect.
    # @param [Hash] configuration options
    @options = {
      'reconnect'  => true,
      'redir_host' => 'redirector.flotype.com',
      'redir_port' => 80,
      'log_level'  => 3, # 0 for no output.
    }
    def self.initialize(options = {})
      Util::log 'initialize called.'
      options.each {|key, value|
        @options[key.to_s] = value
      }
      
      if !(@options.has_key? 'api_key')
        raise ArgumentError, 'No API key specified.'
      end
      
      if Util::has_keys?(@options, 'host', 'port')
        EM::connect(@options['host'], @options['port'], Conn)
      else
        # Support for redirector.
        conn = EM::Protocols::HttpClient2.connect(@options['redir_host'],
                                                  @options['redir_port'])
        req = conn.get({:uri => "/redirect/#{@options['api_key']}"})
        req.callback do |obj|
          obj = JSON::parse obj.content
          if obj.has_key?('data')
            obj = obj['data']
            EM::connect(obj['bridge_host'], obj['bridge_port'], Conn)
          else
            raise Exception, 'Invalid API key.'
          end
        end
      end
    end
    
    # Accessor for @options.
    # @return [Object] options
    def self.options
      @options
    end
    
    # Similar to $(document).ready of jQuery as well as now.ready: takes
    #   callbacks that it will call when the connection handshake has been
    #   completed.
    # @param [#call] fun Callback to be called when the server connects.
    def self.ready fun
      Core::enqueue fun
    end
    
    # Calls a remote function specified by `dest` with `args`.
    # @param [Ref] dest The identifier of the remote function to call.
    # @param [Array] args Arguments to be passed to `dest`.
    def self.send dest, args
      Core::command(:SEND,
                    { :args        => Util::serialize(args),
                      :destination => dest })
    end
    
    # Broadcasts the availability of certain functionality specified by a
    #   proc `fun` under the name of `svc`.
    def self.publish_service svc, handler, fun = nil
      if svc == 'system'
        Util::err("Invalid service name: #{svc}")
      else
        obj = { :name => svc}
        if fun.respond_to? :call
          obj[:callback] = Util::cb(fun)
        end
        Core::command(:JOINWORKERPOOL, obj)
        Core::store(svc, LocalRef.new([svc], handler))
      end
    end
    
    # Join the channel specified by `channel`. Messages from this channel
    #   will be passed in to a handler specified by `handler`. The callback
    #   `fun` is to be called to confirm successful joining of the channel.
    def self.join_channel channel, handler, fun = nil
      obj = { :name => channel, :handler => Util::local_ref(handler)}
      if fun.respond_to? :call
        obj[:callback] = Util::cb(fun)
      end
      Core::command(:JOINCHANNEL, obj)
    end
    
    # Leave a channel.
    def self.leave_channel channel, handler, fun = nil
      obj = { :name => channel, :handler => Util::local_ref(handler)}
      if fun.respond_to? :call
        obj[:callback] = Util::cb(fun)
      end
      Core::command(:LEAVECHANNEL, obj)
    end
    
    # Leave a channel.
    def self.leave_channel channel, handler, fun
      Core::command(:LEAVECHANNEL,
                    { :name     => channel,
                      :handler  => Util::local_ref(handler),
                      :callback => Util::cb(fun) })
    end
    
    # Returns a reference to the service specified by `svc`.
    def self.get_service svc
      Core::lookup ['named', svc, svc]
    end
    
    # Returns a reference to the channel specified by `channel`.
    def self.get_channel channel
      Core::lookup ['channel', channel, "channel:#{channel}"]
    end
    
    # The client's ID.
    def self.client_id
      Core::client_id
    end
  end
end
