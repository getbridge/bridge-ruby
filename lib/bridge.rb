require 'eventmachine'

dirname = File.dirname(File.expand_path(__FILE__))
require dirname + '/util'
require dirname + '/core'
require dirname + '/conn'
require dirname + '/ref'
require dirname + '/callbackref'

module Bridge
  # Usage: Bridge::initialize(opts).
  # Expects to be called inside an EventMachine block.
  def self.initialize(options = {})
    @options = {
      :host      => '127.0.0.1',
      :port      => 8080,
      :api_key   => :null,
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

  def self.send args, dest
    Core::command(:SEND,
                  { :args        => Util::serialize(args),
                    :destination => dest })
  end

  def self.publish_service name, svc, fun
    if svc == 'system'
      Util::err('Invalid service name: ' + svc)
    else
      Core::command(:JOINWORKERPOOL,
                    { :name     => name,
                      :callback => Core::store(fun.hash, CallbackRef(fun))
                    })
    end
    Core::store(name, svc)
  end

  def self.join_channel channel, handler, fun
    Core::command(:JOINCHANNEL,
                  { :name     => channel,
                    :handler  => handler,
                    :callback => Core::store(fun.hash, CallbackRef(fun)) })
  end

  def self.get_service svc
    Core::lookup ['named', svc, svc]
  end

  def self.get_channel channel
    Core::lookup ['channel', channel, 'channel:' + channel]
  end
end
