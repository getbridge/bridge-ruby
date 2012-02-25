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
      Ref.lookup(@path + [atom])
    end

    def call *args
      Core::command :SEND, args
    end

    def respond_to? atom
      true
    end

    def to_json *a
      if @path[1].respond_to? :call
        @path[1] = @path[1].call
      end
      puts 'jsonifying ' + @path.to_json
      {:ref => @path}.to_json *a
    end

    def self.json_create o
      Core::lookup o['ref']
    end
  end
end
