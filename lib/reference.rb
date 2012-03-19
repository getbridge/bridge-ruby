module Bridge
  # Instances of this class represent references to remote services.
  class Reference #:nodoc: all
   
    attr_accessor :options, :address  
    
    def initialize bridge, address, operations = nil
      operations = [] if operations.nil?
      @operations = operations.map do |val|
        val.to_s
      end
      
      @bridge = bridge
      @address = address
    end

    def to_dict op = nil
      result = {}
      address = @address
      if op
        address = address.slice(0..-1)
        address << op
      end
      result[:ref] = address
      if address.length < 4
        result[:operations] = @operations
      end
      return result
    end

    def method_missing atom, *args, &blk
      args << blk if blk
      Util.info "Calling #{@address}.#{atom}";
      destination = self.to_dict atom
      @bridge.send args, destination
    end

    def respond_to? atom
      @operations.include?(atom.to_s) || atom == :to_dict || Class.respond_to?(atom)
    end

  end
end
