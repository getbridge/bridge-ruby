require './conn'

class Core
  def initialize
    @queue, @sess = {}, :null
    @connected = @len = false
  end

  def command cmd, data
    Conn::send_data serialize({:command => cmd, :data => data})
  end

  def lookup ref
    
  end

  def process data
    if !@len
      @len = data.unpack("N")
      return process data[4 .. -1]
    end
    if (@buffer << data).length < @len
      return
    end

    # If this is the first message, set our SessionId and Secret.
    if m = /^([a-zA-Z0-9]+)\|([a-zA-Z0-9]+)$/.match data
      @sess = [m[1], m[2]]
      @queue.each {|fun| fun.call}
      @connected = true
      return
    end
    @buffer, @len = @buffer[@len .. -1], false
    # Else, it is a normal message.
    unser = Util::unserialize data
    dest = lookup unser["destination"]
    dest.call *unser["args"]
  end

  def disconnect
    @connected = false
  end
end
