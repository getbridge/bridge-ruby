module Bridge
  # Wrapper for callbacks passed in as arguments.
  class LocalRef < Ref
    def initialize path, mod
      @mod = mod
      path = ['client', lambda {Core::client_id}] + path
      super(path)
    end

    def method_missing atom, *args, &blk
      (@mod.method atom).call *args
    end

    def method atom
      @mod.method atom
    end

    def call *args
      @mod.call *args
    end

    def respond_to? atom
      @mod.respond_to? atom
    end
  end
end
