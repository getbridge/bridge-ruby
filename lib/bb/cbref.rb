module Bridge
  # Wrapper for callbacks passed in as arguments.
  class CallbackRef < Ref
    def initialize fun
      @fun = fun
      path = ['named', lambda {
                Core::client_id
              }, fun.hash.to_s(36),
              'callback']
      super(path)
    end

    def method_missing atom, *args, &blk
      if atom == 'callback'
        @fun
      end
    end

    def call *args
    end
  end
end
