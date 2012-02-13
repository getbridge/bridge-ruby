module Bridge
  class CallbackRef < Ref
    def initialize path, fun
      super(path)
      @fun = fun
    end

    def method_missing atom, *args, &blk
      if atom == "callback"
        @fun
      end
    end

    def call *args
    end
  end
end
