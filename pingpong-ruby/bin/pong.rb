#!/usr/bin/env ruby

require "bundler/setup"
require "pingpong/version"

require "rubygems"
require "commander/import"
require "webrick"

program :name, 'pong'
program :version, Pingpong::VERSION
program :description, 'pong service for the ping pong system'

def pong_service(request, response)
  begin
    length = Integer(request.path.sub("/pong/", "")) - 3
    response.body = "p#{ 'o' * (length < 0 ? 1 : length) }ng"
  rescue Exception => ex
    response.status = 503
    response.body = "#{request.path} is a bad request.\n#{ex}"
  end
end

command :start do |c|
  c.syntax = 'pong.rb start [options]'
  c.description = 'Starts the pong service.'
  c.option '--port PORT', Integer, 'Port number'
  c.action do |_, options|
    options.default :port => 8080
    if (options.port < 0 || options.port > 65535)
      $stderr.puts "Not a valid port number"
      exit!(1)
    end

    server = WEBrick::HTTPServer.new :Port => options.port
    trap 'INT' do server.shutdown end
    server.mount_proc "/pong" do |req, res|
      pong_service(req,res)
    end
    server.start
  end
end