require 'eventmachine'
require './util'
require './core'
require './conn'

module Bridge
  # Usage: Bridge::initialize(opts).
  # Expects to be called inside an EventMachine block.
  def initialize(options = {})
    @options = {
      :host    => '127.0.0.1',
      :port    => 8080,
      :api_key => :null
    }.merge(options)
    @core = Core.new()
    EventMachine::connect(@options[:host],
                          @options[:port],
                          Conn)
  end

  # Similar to $(document).ready in that it takes callbacks that it
  # will call when the connection handshake has been completed.
  def ready fun
    @queue << fun
  end

  def publishService name, service, fun
    
  end

  def joinChannel name, handler, fun
    
  end

  def getService name, fun
    
  end

  def getChannel name
    
  end
end
