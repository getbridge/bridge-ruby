require 'bridge-ruby'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'abcdefgh', :host => 'localhost', :port => 8090, :log => 5)

  #class ThankHandler
    #def thank msg
      #puts msg
    #end
  #end

  bridge.connect

  #bridge.publish_service("thank", ThankHandler.new)

  test = bridge.get_service('test')
  test.someFunction

end

