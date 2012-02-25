require 'bb/conn'
require 'bb/ref'
require 'bb/sys'
require 'bb/core'
require 'bb/cbref'
require 'bb/util'

require 'eventmachine'

module Bridge

  # Expects to be called inside an EventMachine block in lieu of
  #   EM::connect.
  # @param [Hash] configuration options
  def self.initialize(options = {})
    Util::log 'initialize called.'
    @options = {
      'reconnect'  => true,
      'redir_host' => 'redirector.flotype.com',
      'redir_port' => 80,
      'log_level'  => 3, # 0 for no output.
    }.merge(options)

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
  def self.publish_service svc, handler, fun
    if svc == 'system'
      Util::err("Invalid service name: #{svc}")
    else
      Core::command(:JOINWORKERPOOL,
                    { :name     => svc,
                      :handler  => Util::cb(handler),
                      :callback => Util::cb(fun) })
    end
    Core::store(name, svc)
  end

  # Join the channel specified by `channel`. Messages from this channel
  #   will be passed in to a handler specified by `handler`. The callback
  #   `fun` is to be called to confirm successful joining of the channel.
  def self.join_channel channel, handler, fun
    Core::command(:JOINCHANNEL,
                  { :name     => channel,
                    :handler  => Util::cb(handler),
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
