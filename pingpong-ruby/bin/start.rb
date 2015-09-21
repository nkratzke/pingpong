#!/usr/bin/env ruby

require "bundler/setup"
require "pingpong/version"

require "rubygems"
require "commander/import"
require "webrick"
require "httpclient"

program :name, 'ping'
program :version, Pingpong::VERSION
program :description, 'ping service for the ping pong system'

MAX_TRIES = 100

def ping_service(request, response, webclient, host, port)
  begin
    length = Integer(request.path.sub("/ping/", ""))
    answer = webclient.get("http://#{host}:#{port}/pong/#{length}").body
    response.body = answer
  rescue Exception => ex
    response.status = 503
    response.body = "#{request.path} is a bad request.\n#{ex}"
  end
end

def mping_service(request, response, webclient, host, port)
  begin
    length = Integer(request.path.sub("/mping/", ""))
    retries = 0
    answer = nil
    success = false
    start = Time.now.nsec
    while (retries < MAX_TRIES && !success)
      begin
        answer = webclient.get("http://#{host}:#{port}/pong/#{length}")
        success = (answer.status == 200)
        retries += 1 unless success
      rescue Exception => ex
        retries += 1
      end
    end
    finished = Time.now.nsec

    elapsed = (finished - start) / 1000.0 / 1000.0

    json = {
        'duration': elapsed,
        'length':   answer == nil ? 0 : answer.body.size,
        'document': request.path,
        'status':   answer == nil ? 503 : answer.status,
        'retries':  retries
    }

    response.body = json.to_s
  rescue Exception => ex
    response.status = 503
    response.body = "#{request.path} is a bad request.\n#{ex}"
  end
end

def pong_service(request, response)
  begin
    length = Integer(request.path.sub("/pong/", "")) - 3
    response.body = "p#{ 'o' * (length < 0 ? 1 : length) }ng"
  rescue Exception => ex
    response.status = 503
    response.body = "#{request.path} is a bad request.\n#{ex}"
  end
end

command :pong do |c|
  c.syntax = 'start.rb pong [options]'
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

command :ping do |c|
  c.syntax = 'start.rb ping [options]'
  c.description = 'Starts the pong service.'
  c.option '--port PORT', Integer, 'Port number'
  c.option '--ponghost IP', String, "DNS or IP of pong host"
  c.option '--pongport PORT', Integer, "Portnumber of pong host"
  c.action do |_, options|
    options.default :port => 8080
    options.default :pongport => 8080
    options.default :ponghost => 'localhost'

    if (options.port < 0 || options.port > 65535)
      $stderr.puts "--port: Not a valid port number"
      exit!(1)
    end

    if (options.pongport < 0 || options.pongport > 65535)
      $stderr.puts "--pongport: Not a valid port number"
      exit!(1)
    end

    server = WEBrick::HTTPServer.new :Port => options.port
    trap 'INT' do server.shutdown end

    webclient = HTTPClient.new

    server.mount_proc "/ping" do |req, res|
      ping_service(req,res, webclient, options.ponghost, options.pongport)
    end

    server.mount_proc "/mping" do |req, res|
      mping_service(req,res, webclient, options.ponghost, options.pongport)
    end

    server.start
  end
end