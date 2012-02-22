require 'bb/conn'
require 'bb/ref'
require 'bb/sys'
require 'bb/core'
require 'bb/cbref'
require 'bb/util'

require 'eventmachine'

module Bridge
  # Usage: Bridge::initialize(opts).
  # Expects to be called inside an EventMachine block.
  def self.initialize(options = {})
    Util::log 'initialize called.'
    @options = {
      :host      => '127.0.0.1',
      :port      => 8080,
      :api_key   => nil,
      :reconnect => true
    }.merge(options)
    EventMachine::connect(@options[:host], @options[:port], Bridge::Conn)
  end

  def self.options
    @options
  end

  # Similar to $(document).ready of jQuery as well as now.ready: takes
  # callbacks that it will call when the connection handshake has been
  # completed.
  def self.ready fun
    Core::enqueue fun
  end

  # Calls a remote function specified by `dest` with `args`.
  def self.send dest, args
    Core::command(:SEND,
                  { :args        => Util::serialize(args),
                    :destination => dest })
  end

  # Broadcasts the availability of certain functionality specified by a
  # proc `fun` under the name of `svc`.
  def self.publish_service svc, fun
    if svc == 'system'
      Util::err('Invalid service name: ' + svc)
    else
      Core::command(:JOINWORKERPOOL,
                    { :name     => svc,
                      :callback => Util::cb(fun)
                    })
    end
    Core::store(name, svc)
  end

  # Join the channel specified by `channel`. Messages from this channel
  # will be passed in to a handler specified by `handler`. The callback
  # `fun` is to be called to confirm successful joining of the channel.
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
    Core::command(:GETCHANNEL,
                  { :name     => channel
                  })
    Core::lookup ['channel', channel, 'channel:' + channel]
  end

  # The client's ID.
  def self.client_id
    Core::client_id
  end
end
