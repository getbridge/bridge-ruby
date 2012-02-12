require 'eventmachine'
require './util'
require './core'
require './conn'

module Bridge
  # Usage: Bridge::initialize(opts).
  # Expects to be called inside an EventMachine block.
  def initialize(options = {})
    @options = {
      :host      => '127.0.0.1',
      :port      => 8080,
      :api_key   => :null,
      :reconnect => true
    }.merge(options)
    EventMachine::connect(@options[:host], @options[:port], Conn)
  end

  def options
    @options
  end

  # Similar to $(document).ready of jQuery as well as now.ready: takes
  # callbacks that it will call when the connection handshake has been
  # completed.
  def ready fun
    Core::enqueue fun
  end

  def send args, dest
    Core::command(:SEND,
                  { :args        => Util::serialize(args),
                    :destination => dest })
  end

  def publishService svc, fun
    if service == 'system'
      Util::err('Invalid service name: ' + system)
    else
      Core::command(:JOINWORKERPOOL,
                    { :name     => svc,
                      :callback => Core::lookup fun })
    end
    Core::addService(svc)
  end

  def joinChannel channel, handler, fun
    Core::command(:JOINCHANNEL,
                  { :name     => channel,
                    :handler  => handler,
                    :callback => Core::lookup fun })
  end

  def getService svc
    Core::lookup ['named', svc, svc]
  end

  def getChannel channel
    Core::lookup ['channel', channel, 'channel:' + channel]
  end
end
