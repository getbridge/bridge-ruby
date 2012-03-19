require_relative "reference_dummy.rb"

class BridgeDummy

  attr_accessor  :last_args, :last_dest, :stored
  
  def initialize
    @stored = []
  end
  
  def store_object handler, ops
    @stored << [handler, ops]
    return ReferenceDummy.new
  end
  
  def send args, destination
    @last_args = args
    @last_dest = destination
  end

end