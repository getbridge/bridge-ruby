require 'rubygems' 
require 'sinatra/base'
require 'bridge'
require 'thin'


EventMachine.run do
  
  class ChatServer

    def initialize bridge
      @bridge = bridge
    end
  
    def join name, handler, callback
      @bridge.join_channel 'lobby', handler, &callback
    end
  end
    
  bridge = Bridge::Bridge.new(:host => 'localhost', :port => 8090, :api_key => 'abcdefgh', :log => 5).connect do
    puts 'Connected to Bridge'
  end
  
  bridge.publish_service("chatserver", ChatServer.new(bridge)) do 
    puts('started chatserver')
  end
  
  
  
  
  
  
  # Host static file
  
  class App < Sinatra::Base
      get '/' do
          erb :index, :locals => {:title => 'index'}
      end
  end

  App.run!(:port => 80) 
  
  
end


