require 'bridge-ruby'

EventMachine.run do

  bridge = Bridge::Bridge.new(:api_key => 'myapikey')

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

