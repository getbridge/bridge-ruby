require 'json'
require 'logger'



module Bridge
  module Util
    
    @log = Logger.new(STDOUT)
    
    def self.generateGuid
      (0..12).map{ ('a'..'z').to_a[rand(26)] }.join
    end
    
    def self.ref_callback ref
      CallbackReference.new ref do |*args, &blk|
        args << blk if blk
        self.call *args
      end
    end
    
    def self.set_log_level level
      if level > 2
        @log.level = Logger::INFO
      elsif level == 2
        @log.level = Logger::WARN
      elsif level == 1
        @log.level = Logger::ERROR
      else
        @log.level = Logger::FATAL
      end
    end
    
    def self.info msg
      @log.info msg
    end
    
    def self.warn msg
      @log.warn msg
    end

    def self.error msg
      @log.error msg
    end
   
    def self.stringify obj
      JSON::generate obj
    end
   
    def self.parse str
      JSON::parse str
    end 
    
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
          self
        else
          Class.method atom
        end
      end

      def methods bool
        [:callback]
      end

      def to_dict op = nil
        @ref.to_dict op
      end
      
      def respond_to? atom
        atom == :callback || atom == :to_dict || Class.respond_to?(atom)
      end
      
    end
    
  end
  
end
