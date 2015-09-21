# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pingpong/version'

Gem::Specification.new do |spec|
  spec.name          = "pingpong-ruby"
  spec.version       = Pingpong::VERSION
  spec.authors       = ["Nane Kratzke"]
  spec.email         = ["nane.kratzke@googlemail.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q{Ruby implementation of pingpong.}
  spec.description   = %q{Ruby implementation of pingpong to test REST-API reference performances with ppbench.}
  spec.homepage      = "https://github.com/nkratzke/pingpong"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["setup", "start.rb", "pong.rb"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "commander"
  spec.add_runtime_dependency "webrick"
  spec.add_runtime_dependency "httpclient"
end
