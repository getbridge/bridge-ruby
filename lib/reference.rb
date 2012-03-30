module Bridge
  # Instances of this class represent references to remote services.
  class Reference #:nodoc: all
   
    attr_accessor :operations, :address  
    
    def initialize bridge, address, operations = nil
      @address = address
      # Store operations supported by this reference if any
      operations = [] if operations.nil?
      @operations = operations.map do |val|
        val.to_s
      end
      @bridge = bridge
    end

    def to_dict op = nil
      # Serialize the reference
      result = {}
      address = @address
      # Add a method name to address if given
      if op
        address = address.slice(0..-1)
        address << op
      end
      result[:ref] = address
      # Append operations only if address refers to a handler
      if address.length < 4
        result[:operations] = @operations
      end
      return result
    end

    def method_missing atom, *args, &blk
      # If a block is given, add to arguments list
      args << blk if blk
      Util.info "Calling #{@address}.#{atom}"
      # Serialize destination
      destination = self.to_dict atom.to_s
      # Send RPC
      @bridge.send args, destination
    end

    def respond_to? atom
      @operations.include?(atom.to_s) || atom == :to_dict || Class.respond_to?(atom)
    end

  end
end
