class ConnectionDummy

  attr_accessor :messages, :onopened
  
  def initialize
    @messages = []
    @onopened = false
  end
  
  def onopen *args
    @onopened = true
  end
  
  def onclose *args
  end
  
  def onmessage data, tcp
    messages << data[:data]
  end

end