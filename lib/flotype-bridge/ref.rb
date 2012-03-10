module Flotype
  module Bridge
    # Instances of this class represent references to remote services.
    class Ref
      @@refs = {}
      
      def self.lookup ref
        key = ref[2 .. -1].to_json
        if @@refs[key] == nil
          @@refs[key] = Ref.new(ref)
        end
        @@refs[key]
      end
      
      def initialize path
        @path = path
        @@refs[path[2 .. -1].to_json] = self
      end
      
      def path
        @path
      end
      
      def method_missing atom, *args, &blk
        Core::lookup(@path + [atom]).call *args
      end
      
      def method atom
        Core::lookup(@path + [atom])
      end
      
      def call *args
        Core::command :SEND, {
          :destination => {:ref => @path},
          :args        => Util::inflate(args)
        }
      end
      
      def respond_to? atom
        true
      end
      
      def to_json *a
        if @path[1].respond_to? :call
          @path[1] = @path[1].call
        end
        {:ref => @path}.to_json *a
      end
    end
  end
end
