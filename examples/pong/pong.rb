require 'eventmachine'
require 'bridge'

EventMachine::run {
  Bridge::initialize({:reconnect => false, :port => 8090})
  Bridge::ready lambda {
    puts 'Connected.'
  }
  puts 'enqueued ready func'
  Bridge::publish_service "echo", lambda {|*x| puts *x}
  puts 'published echo service'
  Bridge::publish_service "pong", lambda {|msg, count, fun|
    if msg == "ping"
      puts :pong
      fun.call(count + 1)
    end
  }
  puts 'published pong service'
  Bridge::join_channel("duuuude",
                       lambda {|name, msg|
                         puts(name + ": " + msg)
                       }, lambda {puts "Duuude."})
  puts 'joined channel'
}
