class BridgeDummy

  attr_accessor  :last_args, :last_dest
  
  def send args, destination
    @last_args = args
    @last_dest = destination
  end

end