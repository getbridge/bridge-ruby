require 'bb/svc'
require 'bb/conn'
require 'bb/ref'
require 'bb/sys'
require 'bb/core'
require 'bb/localref'
require 'bb/callback'
require 'bb/util'

require 'eventmachine'

module Bridge

  # Expects to be called inside an EventMachine block in lieu of
  #   EM::connect.
  # @param [Hash] configuration options
  @options = {
    'reconnect'  => true,
    'redir_host' => 'redirector.flotype.com',
    'redir_port' => 80,
    'log_level'  => 2, # 0 for no output.
  }
  def self.initialize(options = {}, &fun)
    Util::log 'initialize called.'
    @options = @options.merge(options)

    self.ready fun if fun
    
    if !(@options.has_key? 'api_key')
      raise ArgumentError, 'No API key specified.'
    end

    if Util::has_keys?(@options, 'host', 'port')
      EM::connect(@options['host'], @options['port'], Bridge::Conn)
    else
      # Support for redirector.
      conn = EM::Protocols::HttpClient2.connect(@options['redir_host'],
                                                @options['redir_port'])
      req = conn.get({:uri => "/redirect/#{@options['api_key']}"})
      req.callback do |obj|
        obj = JSON::parse obj.content
        if obj.has_key?('data')
          obj = obj['data']
          EM::connect(obj['bridge_host'], obj['bridge_port'], Bridge::Conn)
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
  def self.ready &fun
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
  def self.publish_service svc, handler, &fun
    if svc == 'system'
      Util::err("Invalid service name: #{svc}")
    else
      obj = { :name => svc}
      obj[:callback] = Util::cb(fun) if fun
      Core::command(:JOINWORKERPOOL, obj)
      Core::store(svc, Bridge::LocalRef.new([svc], handler))
    end
  end

  # Join the channel specified by `channel`. Messages from this channel
  #   will be passed in to a handler specified by `handler`. The callback
  #   `fun` is to be called to confirm successful joining of the channel.
  def self.join_channel channel, handler, &fun
    obj = { :name => channel}
    if handler.is_a? Ref
      obj[:handler] = Ref
    else
      obj[:handler] = Util::local_ref(handler)
    end
    obj[:callback] = Util::cb(fun) if fun
    Core::command(:JOINCHANNEL, obj)
  end

  # Leave a channel.
  def self.leave_channel channel, handler, &fun
    obj = { :name => channel }
    if handler.is_a? Ref
      obj[:handler] = Ref
    else
      obj[:handler] = Util::local_ref(handler)
    end
    obj[:callback] = Util::cb(fun) if fun
    Core::command(:LEAVECHANNEL, obj)
  end
  
  # Returns a reference to the service specified by `svc`.
  def self.get_service svc, &fun
    ref = Core::lookup ['named', svc, svc]
    fun.call(ref) if fun
  end

  # Returns a reference to the channel specified by `channel`.
  def self.get_channel channel, &fun
    Core::command(:GETCHANNEL, {:name => channel})
    ref = Core::lookup ['channel', channel, "channel:#{channel}"]
    fun.call(ref, channel) if fun
    return ref
  end

  # The client's ID.
  def self.client_id
    Core::client_id
  end
end
