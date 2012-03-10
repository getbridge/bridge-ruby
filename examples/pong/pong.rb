require 'eventmachine'
require 'flotype-bridge'


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
  Flotype::Bridge::initialize({ :reconnect => false,
                       :host => '127.0.0.1',
                       :port => 8090})
  Flotype::Bridge::ready lambda {
    puts 'Connected.'
  }
  puts 'enqueued ready func'
  Flotype::Bridge::publish_service("pong", EchoModule)
  puts 'published pong service'
  Flotype::Bridge::join_channel("duuuude", EchoModule, lambda {puts "Duuude."})
  puts 'joined channel'
}
