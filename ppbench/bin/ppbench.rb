#!/usr/bin/env ruby

require 'bundler/setup'
require 'rubygems'

require 'ppbench'
require 'commander/import'

program :name, 'ppbench'
program :version, "#{Ppbench::VERSION}"
program :description, 'Ping pong benchmark'
program :help, 'Author', 'Nane Kratzke <nane.kratzke@fh-luebeck.de>'

def run(args, options)
  options.default :min => 1, :max => 500000, :concurrency => 10
  options.default :tag => ''
  options.default :coverage => 0.1

  logfile = args[0]

  Ppbench::run_bench(
      options.host,
      logfile,
      tag: options.tag,
      coverage: options.coverage,
      min: options.min,
      max: options.max,
      concurrency: options.concurrency
  )
end

command :run do |c|
  c.syntax = 'ppbench run --host http://1.2.3.4:8080/ping log.csv'
  c.description = 'Runs a ping pong benchmark'

  c.option '--host STRING', String, 'Host'
  c.option '--tag STRING', String, 'A tag to categorize the run (defaults to empty String)'
  c.option '--min INTEGER', Integer, 'Minimum message size [bytes] (defaults to 1)'
  c.option '--max INTEGER', Integer, 'Maximum message size [bytes] (defaults to 500.000)'
  c.option '--coverage FLOAT', Float, 'Amount of test messages to send (defaults to 0.33)'
  c.option '--concurrency INTEGER', Integer, 'Concurrency level (defaults to 10)'

  c.action do |args, options|
    run(args, options)
    print("Finished\n")
  end
end
