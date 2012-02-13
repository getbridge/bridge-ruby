require 'eventmachine'
dirname = File.dirname(File.expand_path(__FILE__))
require dirname+'/../../lib/bridge'

EventMachine::run {
  Bridge::initialize({:reconnect => false, :port => 8090})
}
