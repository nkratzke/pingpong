require "ppbench/version"
require "parallel"
require "csv"
require "net/http"
require "progressbar"
require "thread"
require "json"

module Ppbench

  LOG_HEADER = [
      "Tag",
      "Document Path",
      "Failed requests",
      "Concurrency Level",
      "Total transferred",
      "Time per request",
      "Retries",
      "Response Code"
  ]


  def self.run_bench(host, log, tag: '', coverage: 0.1, min: 1, max: 500000, concurrency: 10)
    rounds = ((max - min) * coverage).to_i

    CSV.open(log, 'w', write_headers: true, headers: Ppbench::LOG_HEADER, force_quotes: true) do |logger|

      logfile = Mutex.new
      progress = ProgressBar.new("Running", rounds)

      Parallel.each(1.upto(rounds), in_threads: concurrency) do |_|

        length = Random.rand(min..max)
        document = "/mping/#{length}"

        answer = {}
        begin
          uri = URI("#{host}#{document}")
          response = Net::HTTP.get(uri)
          answer = JSON.parse(response)
        rescue Exception => e
          print ("Problems processing '#{uri}' due to #{e}")
        end

        time_taken = answer['duration'] # in milliseconds
        length = answer['length'] # message length
        code = answer['code'] # HTTP response code
        retries = answer['retries'] # Amount of retries
        failed = (answer['code'] == 200) ? 0 : 1

        logfile.synchronize do
          progress.inc
          logger << [
              "#{tag}",
              "#{document}",
              "#{failed}",
              "#{concurrency}",
              "#{length}",
              "#{time_taken}", # time per request missing
              "#{retries}",
              "#{code}"
          ]
        end
      end
    end

  end

end
