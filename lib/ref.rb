module Bridge
  class Ref
    def initialize type, id, service
      @type, @id, @svc = type, id, service
    end
    
    def method_missing atom, *args, &blk
      Core::command(:SEND,
                    { :destination => {:ref => [@type, @id, @svc, atom]},
                      :args        => args })
    end
  end
end
