module Bridge
  # Wrapper for callbacks passed in as arguments.
  class CallbackReference < Proc
    
    def initialize ref
      @ref = ref
    end

    def callback *args, &blk
      args << blk if blk
      @ref.callback *args 
    end

    def call *args, &blk
      args << blk if blk
      @ref.callback *args
    end

    def method atom
      if atom.to_s == 'callback'
        @ref.callback
      else
        nil
      end
    end

    def methods bool
      [:callback]
    end

    def to_dict
      @ref.to_dict 'callback'
    
    def respond_to? atom
      atom = atom.to_s
      atom == 'callback' || atom == 'to_dict'
    end
  end
end
