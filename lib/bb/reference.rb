module Bridge
  # Instances of this class represent references to remote services.
  class Reference
   
    attr_accessor :options, :address  
    
    def initialize bridge, address, operations = []
      
      @operations = operations
      @bridge = bridge
      @address = address
      
    end

    def to_dict op
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
      Util.info "Calling #{@address} #{args}";
      destination = self.to_dict atom
      @bridge.send args destination
    end

    def respond_to? atom
      true
    end

  end
end
