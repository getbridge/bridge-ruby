require 'serializer.rb'
require 'reference.rb'

module Bridge
  class Client #:nodoc: all
    def initialize(bridge, id)
      @bridge, @id = bridge, id
    end

    def get_service(svc)
      Reference.new(@bridge, ['client', @id, svc])
    end
  end
end
