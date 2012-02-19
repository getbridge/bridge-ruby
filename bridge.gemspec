require File.expand_path('../lib/bb/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'bridge'
  s.version = Bridge::VERSION
  s.homepage = 'http://flotype.com'
  # s.rubyforge_project = 'brooklyn'

  s.authors = ["Flotype"]
  s.email   = ["team@flotype.com"]

  s.files = `git ls-files`.split("\n")

  s.add_dependency 'eventmachine', '>= 0.12.0'
  s.add_dependency 'json', ">= 1.5.0"

  s.summary = 'Ruby/Bridge library'
  s.description = "Ruby client for Flotype Bridge."

  s.rdoc_options = ["--title", "Bridge", "--main", "README.md", "-x", "lib/bb/version"]
  s.extra_rdoc_files = ["README.md"] + `git ls-files -- docs/*`.split("\n")
end
