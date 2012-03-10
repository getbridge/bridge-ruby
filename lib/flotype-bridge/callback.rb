module Flotype
  module Bridge
    # Wrapper for callbacks passed in as arguments.
    class Callback
      def initialize fun
        @fun = fun
      end
      
      def callback *args
        @fun.call *args
      end
      
      def call *args
        @fun.call(*call)
      end
      
      def method atom
        if atom.to_s == 'callback'
          @fun
        else
          nil
        end
      end
      
      def methods bool
        [:callback]
      end
      
      def respond_to? atom
        atom = atom.to_s
        atom == 'call' || atom == 'to_json'
      end
    end
  end
end
