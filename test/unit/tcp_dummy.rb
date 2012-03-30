class TcpDummy

  attr_accessor :last_send
  
  def initialize *args
    
  end
  
  def send *args
    @last_send = args
  end
end