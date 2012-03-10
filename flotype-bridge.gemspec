require File.expand_path('../lib/flotype-bridge/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'flotype-bridge'
  s.version = Flotype::Bridge::VERSION
  s.homepage = 'http://flotype.com'

  s.authors = ["Flotype"]
  s.email   = ["team@flotype.com"]

  s.files = `git ls-files`.split("\n")

  s.add_dependency 'eventmachine', '>= 0.12.0'
  s.add_dependency 'json', ">= 1.5.0"

  s.add_development_dependency 'yard', '>= 0.7.2'
  s.add_development_dependency 'rake-compiler', '>= 0.7.9'

  s.summary = 'Ruby/Bridge library'
  s.description = "Ruby client for Flotype Bridge."

  s.rdoc_options = ["--title", "Flotype Bridge", "--main", "README.md", "-x", "lib/bb/version"]
  s.extra_rdoc_files = ["README.md"] + `git ls-files -- docs/*`.split("\n")
end
