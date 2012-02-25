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
      :api_key    => nil,
      :reconnect  => true,
      :redir_host => 'redirector.flotype.com',
      :redir_port => 7000
    }.merge(options)

    if Util::has_keys?(@options, 'host', 'port')
      EM::connect(@options['host'], @options['port'], Bridge::Conn)
    elsif Util::has_keys?(@options, 'api_key', 'redir_host', 'redir_port')
      # Support for redirector.
      conn = EM::Protocols::HttpClient2.connect(@options[:redir_host],
                                                @options[:redir_port])
      req = conn.get({'uri' => "/redirect/#{@options[:api_key]}"})
      req.callback {|obj|
        obj = obj.to_json
        EM::connect(obj['host'], obj['port'], Bridge::Conn)
      }
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
  def self.publish_service svc, fun
    if svc == 'system'
      Util::err("Invalid service name: #{svc}")
    else
      Core::command(:JOINWORKERPOOL,
                    { :name     => svc,
                      :callback => Util::cb(fun)
                    })
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
                    :callback => Util::cb(fun)
                  })
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
