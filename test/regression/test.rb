require 'eventmachine'
messages = []

class Test 
  def initialize failureMessage, logLevel, stages
    @stages = stages
    @stage = 0
    @failureMessage = failureMessage
    @timer = EM::Timer.new(3) { self.fail "timeout" }
    if !(logLevel == 0 || logLevel == 1 || logLevel == 2)
      raise "Invalid log level #{logLevel}"
    end
    @logLevel = logLevel
  end

  def advance expected
    if @stage != expected
      self.fail "out of order: at stage #{@stage}, not #{expected}"
    else
      @stage += 1
      @timer.cancel
      @timer = EM::Timer.new(3) { self.fail "timeout" }
    end
  end

  def close
    if @stage != @stages
      puts "Failure: reached stage #{@stage} of #{@stages}"
    end
    Process::exit
  end

  def fail(m = failureMessage)
    puts "============================================"
    puts " Description: ", m
    if logLevel != 0
      puts " Message stack: "
      messages.each {|msg| puts msg}
    end
    self.close
  end

  def log msg
    if logLevel != 0
      messages += msg
      if logLevel == 2
        puts msg
      end
    end
  end

end
