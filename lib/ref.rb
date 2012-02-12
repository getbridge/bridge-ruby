module Bridge
  class Ref
    @@refs = {}

    def self.lookup ref
      if @@refs[ref]  == nil
        Ref.new(ref)
      end
      @@refs[ref]
    end

    def initialize path
      @path = path
      @@refs[ref] = self
    end

    def method_missing atom, *args, &blk
      Ref.lookup (path + [atom])
    end

    def call *args
      Core::send(args, @path)
    end

    def respond_to? atom
      true
    end

    def to_json
      @path.to_json
    end

    def self.json_create o
      Core::lookup o['ref']
    end
  end
end
