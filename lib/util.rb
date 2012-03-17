require 'json'

module Bridge
  module Util
    
    def self.generateGuid
      (0..12).map{ ('a'..'z').to_a[rand(26)] }.join
    end
    
    def self.ref_callback ref
      CallbackReference.new ref do |*args, &blk|
        args << blk if blk
        self.call *args
      end
    end
    
    def self.info msg, level = 3
      #opts = Bridge::options
      #if level <= opts['log_level']
        puts msg
      #end
    end
    
    def self.warn msg, level = 2
      #opts = Bridge::options
      #if level <= opts['log_level']
        puts msg
      #end
    end

    def self.error msg, level = 1
      #opts = Bridge::options
      #if level <= opts['log_level']
        puts msg
      #end
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
