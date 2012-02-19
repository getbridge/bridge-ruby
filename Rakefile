require 'rubygems'
GEMSPEC = Gem::Specification.load('bridge.gemspec')

require 'rake/clean'
task :clobber => :clean

desc "Build bridge, then run tests."
task :default => [:test, :package]

desc 'Generate documentation'
begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', '-', 'docs/*.md']
    t.options = ['--main', 'README.md', '--no-private']
  end
rescue LoadError
  task :yard do puts "Please install yard first!"; end
end
