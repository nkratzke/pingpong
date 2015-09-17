# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ppbench/version'

Gem::Specification.new do |spec|
  spec.name          = "ppbench"
  spec.version       = Ppbench::VERSION
  spec.authors       = ["Nane Kratzke"]
  spec.email         = ["nane.kratzke@fh-luebeck.de"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  end

  spec.summary       = %q{ppbench - a REST ping pong benchmark}
  spec.description   = %q{A tool to run ping pong benchmark to figure out HTTP REST performances.}
  spec.homepage      = "https://github.com/nkratzke/pingpong"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["ppbench.rb"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "commander"
  spec.add_runtime_dependency "parallel"
  spec.add_runtime_dependency "progressbar"
  spec.add_runtime_dependency "descriptive_statistics"
  spec.add_runtime_dependency "terminal-table"
  spec.add_runtime_dependency "httpclient"

end
