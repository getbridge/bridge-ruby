require 'eventmachine'
require 'bridge'

EventMachine::run {
  Bridge::initialize({:reconnect => false, :port => 8090})
  Bridge::ready lambda {
    puts 'Connected.'
  }
  Bridge::publish_service "echo", lambda {|*x| puts *x}
  Bridge::publish_service "pong", lambda {|msg, count, fun|
    if msg == "ping"
      puts :pong
      fun.call(count + 1)
    end
  }
  Bridge::join_channel("duuuude", lambda {|name, msg|
                         puts(name + ": " + msg)
                       }, lambda {puts "Duuude."})
}
