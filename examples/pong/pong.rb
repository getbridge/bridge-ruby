require 'eventmachine'
require 'bridge'


module EchoModule
  def self.echo name, msg
    puts(name + ": " + msg)
  end
  def self.pong msg, count, fun
    if msg == "ping"
      puts :pong
      fun.call(count + 1)
    end
  end
end

EventMachine::run {
  Bridge::initialize({:reconnect => false,
                       :host => '127.0.0.1',
                       :port => 8090})
  Bridge::ready lambda {
    puts 'Connected.'
  }
  puts 'enqueued ready func'
  Bridge::publish_service("pong", EchoModule)
  puts 'published pong service'
  Bridge::join_channel("duuuude", EchoModule, lambda {puts "Duuude."})
  puts 'joined channel'
}
