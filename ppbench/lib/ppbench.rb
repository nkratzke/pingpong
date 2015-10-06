require "ppbench/version"
require "parallel"
require "csv"
require "httpclient"
require "progressbar"
require "thread"
require "json"
require "timeout"
require "descriptive_statistics"

module Ppbench

  def self.naming=(json)
    @naming = json
  end

  def self.machine(key)
    return key if @naming.empty?
    return key unless @naming.key?('machines')
    name = @naming['machines'][key]
    name == nil ? key : name
  end

  def self.experiment(key)
    return key if @naming.empty?
    return key unless @naming.key?('experiments')
    name = @naming['experiments'][key]
    name == nil ? key : name
  end

  def self.precision=(v)
    @precision = v
  end

  def self.precision
    @precision
  end

  def self.alpha=(v)
    @alpha = v
  end

  def self.alpha
    @alpha
  end

  def self.precision_error(length)
    """
    Sorry, we have not enough data for messages of about #{length} byte length.
    You may want to reduce the precision with the global --precision flag.
    Current precison is #{Ppbench::precision}.
    So you could collect more data (preferred) or reduce the precision value.
    """
  end

  R_COLORS = [
      '0.5,0.5,0.5',
      '0.96,0.26,0.21',
      '0.25,0.31,0.71',
      '0.13,0.59,0.95',
      '0,0.59,0.53',
      '0.30,0.69,0.31',
      '0.8,0.86,0.22',
      '1,0.6,0.03',
      '1,0.6,0',
      '1,0.34,0.13'
  ]

  R_NO_SYMBOL = "16"

  R_SYMBOLS = "c(1,2,3,4,5,6,7,8,9,10)"

  LOG_HEADER = [
      "Machine Tag",
      "Experiment Tag",
      "Document Path",
      "Failed requests",
      "Concurrency Level",
      "Total transferred",
      "Time per request",
      "Transfer rate",
      "Requests per second",
      "Retries",
      "Response Code"
  ]

  # Runs a benchmark against a host and stores benchmark data in a log file.
  #
  def self.run_bench(host, log, machine_tag: '', experiment_tag: '', timeout: 60, repetitions: 10, coverage: 0.1, min: 1, max: 500000, concurrency: 10)
    rounds = ((max - min) * coverage).to_i

    CSV.open(log, 'w', write_headers: true, headers: Ppbench::LOG_HEADER, force_quotes: true) do |logger|

      logfile = Mutex.new
      progress = ProgressBar.new("Running", rounds)

      webclient = HTTPClient.new

      Parallel.each(1.upto(rounds), in_threads: concurrency) do |_|

        length = Random.rand(min..max)
        document = "/mping/#{length}"

        results = {
            duration: [],
            length: [],
            code: [],
            retries: [],
            fails: []
        }
        begin
          #uri = URI("#{host}#{document}")
          1.upto(repetitions) do
            answer = {}
            Timeout::timeout(timeout) do
              response = webclient.get("#{host}#{document}").body
              answer = JSON.parse(response)
            end
            results[:duration] << answer['duration']
            results[:length] << answer['length']
            results[:code] << answer['code']
            results[:retries] << answer['retries']
            results[:fails] << (answer['code'] == 200 ? 0 : 1)
          end
        rescue Exception => e
          print ("Timeout of '#{host}#{document}'")
          print ("#{e}")
        end

        unless results[:duration].empty?
          time_taken = results[:duration].mean # in milliseconds
          length = results[:length].median # message length
          transfer_rate = results[:length].sum * 1000 / results[:duration].sum
          code = results[:code].first # HTTP response code
          retries = results[:retries].sum # Amount of retries
          failed = results[:fails].sum # Amount of fails

          requests_per_second = 1000 / time_taken

          logfile.synchronize do
            progress.inc

            logger << [
                "#{machine_tag}",
                "#{experiment_tag}",
                "#{document}",
                "#{failed}",
                "#{concurrency}",
                "#{length}",
                "#{time_taken}",
                "#{transfer_rate}",
                "#{requests_per_second}",
                "#{retries}",
                "#{code}"
            ]
          end
        end
      end
    end
  end

  # Load CSV files and conversion to better analyzable format (List of hashes)
  #
  def self.load_data(files)
    files.map do |file|
      rows = CSV.read(file, headers: true)

      rows.map do |row|
        {
            :experiment => row.key?('Experiment Tag') ? row['Experiment Tag'] : nil,
            :machine => row.key?('Machine Tag') ? row['Machine Tag'] : nil,
            :document => row.key?('Document Path') ? row['Document Path'] : nil,
            :length => row.key?('Total transferred') ? row['Total transferred'].to_i : nil,
            :failed => row.key?('Failed requests') ? row['Failed requests'].to_i : nil,
            :tpr => row.key?('Time per request') ? row['Time per request'].to_f : nil,
            :transfer_rate => row.key?('Transfer rate') ? row['Transfer rate'].to_f : nil,
            :rps => row.key?('Requests per second') ? row['Requests per second'].to_f : nil,
            :retries => row.key?('Retries') ? row['Retries'].to_i : nil,
            :response_code => row.key?('Response Code') ? row['Response Code'].to_i : nil
        }
      end
    end.flatten
  end

  # Filter benchmark data.
  #
  def self.filter(data, maxsize: 2 ** 64, experiments: [], machines: [], fails: 0)
    data.select { |entry| entry[:tpr] > 0 }
        .select { |entry| entry[:failed] <= fails }
        .select { |entry| entry[:length] <= maxsize }
        .select { |entry| machines.include?(entry[:machine]) || machines.empty? }
        .select { |entry| experiments.include?(entry[:experiment]) || experiments.empty? }
  end

  # Aggregate benchmark data.
  # {
  #    'weave': {
  #       'm.large': [{ machine: String, experiment: String, document: String, length: value, tpr: Integer, ... }]
  #       }, ...
  #    },
  #    'docker': { ... },
  #    'bare': { ... }
  # }
  def self.aggregate(data)
    experiments = data.group_by { |entry| entry[:experiment] }
    experiments.map do |experiment, values|
      machines = values.group_by { |entry| entry[:machine] }
      [
          experiment,
          machines
      ]
    end.to_h
  end

  # Determines biggest value of aggregated data.
  #
  def self.maximum(data, of: :tpr)
    y = 0
    for experiment, machines in data
      for machine, values in machines
        m = values.max_by { |e| e[of] }
        y = (y > m[of] ? y : m[of])
      end
    end
    y
  end

  # Prepares a plot to present absolute values.
  #
  def self.prepare_plot(
      maxy,
      receive_window: 87380,
      length: 500000,
      xaxis_title: "Message Length",
      xaxis_unit: "kB",
      yaxis_title: "Transfer Rate",
      yaxis_unit: "MB/sec",
      title: "Data Transfer Rates",
      subtitle: ""
  )
    recwindow = receive_window == 0 ? '' : "abline(v = seq(#{receive_window}, #{length}, by=#{receive_window}), lty='dashed')"

    """
    plot(x=c(0), y=c(0), xlim=c(0, #{length}), ylim=c(0, #{maxy}), main='#{title}\\n(#{subtitle})', xlab='#{xaxis_title} (#{xaxis_unit})', ylab='#{yaxis_title} (#{yaxis_unit})', xaxt='n', yaxt='n', pch=NA)
   	#{recwindow if receive_window < length }
    """
  end

  # Prepares a plot to present relative comparisons.
  #
  def self.prepare_comparisonplot(
      maxy,
      receive_window: 87300,
      length: 50000,
      xaxis_title: "Message Length (kB)",
      xaxis_unit: "kB",
      yaxis_title: "Relative performance compared with reference experiment (%)",
      yaxis_unit: "%",
      title: "Relative performance (Data Transfer Rate)",
      subtitle: ""
  )
    recwindow = receive_window == 0 ? '' : "abline(v = seq(#{receive_window}, #{length}, by=#{receive_window}), lty='dashed')"

    """
    plot(x=c(0), y=c(0), xlim=c(0, #{length}), ylim=c(0, #{maxy}), main='#{title}\\n(#{subtitle})', xlab='#{xaxis_title} (#{xaxis_unit})', ylab='#{yaxis_title} (#{yaxis_unit})', xaxt='n', yaxt='n', pch=NA)
   	#{recwindow if receive_window < length}
    """
  end

  # Adds a serie to a plot.
  #
  def self.add_series(
      data,
      to_plot: :tpr,
      color: 'grey',
      symbol: 1,
      alpha: Ppbench::alpha,
      length: 500000,
      confidence: 90,
      no_points: false,
      with_bands: false
  )
    """
    #{points(data, to_plot: to_plot, color: color, symbol: symbol, alpha: alpha) unless no_points }
    #{bands(data, to_plot: to_plot, color: color, length: length, confidence: confidence) if with_bands }
    """
  end

  # Adds a compare line to a comparison plot.
  #
  def self.add_comparisonplot(
      reference,
      serie,
      to_plot: :tpr,
      color: 'grey',
      symbol: 1,
      length: 500000,
      n: Ppbench::precision,
      nknots: Ppbench::precision
  )
    step = length / n
    references = reference.map { |v| [v[:length], v[to_plot]] }
    ref_values = 1.upto(n).map do |i|
      vs = references.select { |p| p[0] < i * step && p[0] >= (i - 1) * step }.map { |p| p[1] }

      if vs.empty?
        $stderr.puts precision_error(i * step)
        exit!
      end

      [
          i * step,
          vs.median
      ]
    end.to_h

    series = serie.map { |v| [v[:length], v[to_plot]] }
    serie_values = 1.upto(n).map do |i|
      vs = series.select { |p| p[0] < i * step && p[0] >= (i - 1) * step }.map { |p| p[1] }

      if vs.empty?
        $stderr.puts precision_error(i * step)
        exit!
      end

      [
          i * step,
          vs.median
      ]
    end.to_h

    xs = []
    ys = []

    ref_values.each do |x, y|
      if serie_values.key? x
        xs << x
        ys << serie_values[x] / y
      end
    end

    """
    xs=c(#{ xs * ',' })
    ys=c(#{ ys * ',' })
    median <- smooth.spline(xs, ys, nknots=#{nknots})
    lines(median, lwd=2, col=rgb(#{color}))
    """
  end

  # Generates scatter plot of points for plots.
  #
  def self.points(data, to_plot: :tpr, color: 'grey', alpha: Ppbench::alpha, symbol: 1)
    points = data.map { |v| [v[:length], v[to_plot]] }
    xs = "c(#{points.map { |e| e[0] } * ','})"
    ys = "c(#{points.map { |e| e[1] } * ','})"

    """
    xs = #{xs}
    ys = #{ys}
    points(x=xs,y=ys, col=rgb(#{color},alpha=#{ alpha }), pch=#{ symbol })
    """
  end

  # Generates median lines and confidence bands for plots.
  #
  def self.bands(data, to_plot: :tpr, n: Ppbench::precision, length: 500000, color: 'grey', confidence: 90, nknots: Ppbench::precision)

    step = length / n
    points = data.map { |v| [v[:length], v[to_plot]] }
    values = 1.upto(n).map do |i|
      [
          i * step,
          points.select { |p| p[0] < i * step && p[0] >= (i - 1) * step }.map { |p| p[1] }
      ]
    end

    upper_confidence = 100 - (100 - confidence) / 2
    semi_upper_confidence = 100 - (100 - confidence / 2) / 2
    lower_confidence = (100 - confidence) / 2
    semi_lower_confidence = (100 - confidence / 2) / 2

    summary = values.map do |x,vs|

      if vs.empty?
        $stderr.puts precision_error(x)
        exit!
      end

      {
          :x => x,
          :lower => vs.percentile(lower_confidence),
          :semi_lower => vs.percentile(semi_lower_confidence),
          :median => vs.median,
          :semi_upper => vs.percentile(semi_upper_confidence),
          :upper => vs.percentile(upper_confidence)
      }
    end

    xs = "c(#{summary.map { |v| v[:x] } * ','})"
    medians = "c(#{summary.map { |v| v[:median] } * ','})"
    lowers = "c(#{summary.map { |v| v[:lower] } * ','})"
    semi_lowers = "c(#{summary.map { |v| v[:semi_lower] } * ','})"
    uppers = "c(#{summary.map { |v| v[:upper] } * ','})"
    semi_uppers = "c(#{summary.map { |v| v[:semi_upper] } * ','})"

    """
    xs = #{xs}
    medians = #{medians}
    lowers = #{lowers}
    semi_lowers = #{semi_lowers}
    uppers = #{uppers}
    semi_uppers = #{semi_uppers}

    low <- smooth.spline(xs, lowers, nknots=#{nknots})
    semi_low <- smooth.spline(xs, semi_lowers, nknots=#{nknots})
    up <- smooth.spline(xs, uppers, nknots=#{nknots})
    semi_up <- smooth.spline(xs, semi_uppers, nknots=#{nknots})
    median <- smooth.spline(xs, medians, nknots=#{nknots})
    polygon(c(low$x, rev(up$x)), c(low$y, rev(up$y)), col = rgb(#{color},alpha=0.10), border=NA)
    polygon(c(semi_low$x, rev(semi_up$x)), c(semi_low$y, rev(semi_up$y)), col = rgb(#{color},alpha=0.15), border=NA)
    lines(median, lwd=2, col=rgb(#{color}))
    lines(low, col=rgb(#{color},alpha=0.50), lty='dashed', lwd=0.5)
    lines(up, col=rgb(#{color},alpha=0.50), lty='dashed', lwd=0.5)
    """


  end

  # Generates an R plot output script which can be used for plotting benchmark data
  # as scatter plot with optional confidence bands.
  #
  def self.plotter(
      data,
      to_plot: :tpr,
      machines: [],
      experiments: [],
      receive_window: 87380,
      xaxis_max: 500000,
      confidence: 90,
      no_points: false,
      with_bands: false,
      yaxis_max: 10000000,
      yaxis_steps: 10,
      xaxis_steps: 10,
      xaxis_title: "",
      xaxis_unit: "",
      xaxis_divisor: 1000,
      yaxis_title: "",
      yaxis_unit: "",
      yaxis_divisor: 1000000,
      title: "",
      subtitle: "",
      legend_position: "topright"
  )
    series_data = []
    series_names = []
    series_colors = R_COLORS

    for exp in experiments
      for machine in machines
        if (data.include? exp) && (data[exp].include? machine)
          series_data << data[exp][machine]
          series_names << "'#{Ppbench::experiment(exp)} on #{Ppbench::machine(machine)}'"
        end
      end
    end

    colors = "c(#{series_colors.map { |c| "rgb(#{c})" } * ','})"

    sym = 1;
    r = "#{prepare_plot(yaxis_max, receive_window: receive_window, length: xaxis_max, title: title, xaxis_title: xaxis_title, xaxis_unit: xaxis_unit, yaxis_title: yaxis_title, yaxis_unit: yaxis_unit, subtitle: subtitle)}\n"

    for serie in series_data
      r += add_series(serie, to_plot: to_plot, with_bands: with_bands, no_points: no_points, color: series_colors.shift, symbol: sym, length: xaxis_max, confidence: confidence)
      sym = sym + 1
    end

    symbols = no_points ? R_NO_SYMBOL : R_SYMBOLS

    r + """
    xa = seq(0, #{xaxis_max}, by=#{xaxis_max/xaxis_steps})
    ya = seq(0, #{yaxis_max}, by=#{yaxis_max/yaxis_steps})
    axis(1, at = xa, labels = paste(xa/#{xaxis_divisor}, '#{xaxis_unit}', sep = ' ' ))
    axis(2, at = ya, labels = paste(ya/#{yaxis_divisor}, '#{yaxis_unit}', sep = ' ' ))
    legend('#{legend_position}', cex=0.9, pch=#{symbols}, col=#{colors}, c(#{series_names * ',' }),box.col=rgb(1,1,1,0), bg=rgb(1,1,1,0.75))
    """
  end

  # Generates an R plot output script which can be used for plotting comparison plots
  # of benchmark data.
  #
  def self.comparison_plotter(
      data,
      yaxis_max: 1.5,
      to_plot: :transfer_rate,
      machines: [],
      experiments: [],
      receive_window: 87380,
      xaxis_max: 500000,
      xaxis_steps: 10,
      xaxis_title: "",
      xaxis_unit: "",
      xaxis_divisor: 1000,
      yaxis_title: "",
      yaxis_unit: "%",
      title: "",
      subtitle: "",
      legend_position: "topright"
  )
    series_data = []
    series_names = []
    series_colors = R_COLORS

    ref = true
    for exp in experiments
      for machine in machines
        reference = ref ? 'Reference: ' : ''
        ref = false
        if (data.include? exp) && (data[exp].include? machine)
          series_data << data[exp][machine]
          series_names << "'#{reference}#{Ppbench::experiment(exp)} on #{Ppbench::machine(machine)}'"
        end
      end
    end

    colors = "c(#{series_colors.map { |c| "rgb(#{c})" } * ','})"

    sym = 1;
    r = "#{prepare_comparisonplot(yaxis_max, receive_window: receive_window, length: xaxis_max, title: title, subtitle: subtitle, xaxis_title: xaxis_title, xaxis_unit: xaxis_unit, yaxis_title: yaxis_title, yaxis_unit: yaxis_unit)}\n"

    reference = series_data.first

    for serie in series_data
      r += add_comparisonplot(reference, serie, to_plot: to_plot, color: series_colors.shift, symbol: sym, length: xaxis_max)
      sym = sym + 1
    end

    r + """
    xa = seq(0, #{xaxis_max}, by=#{xaxis_max/xaxis_steps})
    ya = seq(0, #{yaxis_max}, by=#{0.1})
    axis(1, at = xa, labels = paste(xa/#{xaxis_divisor}, '#{xaxis_unit}', sep = '' ))
    axis(2, at = ya, labels = paste(ya * 100, '#{yaxis_unit}', sep = '' ))
    legend('#{legend_position}', cex=0.9, pch=c(#{R_NO_SYMBOL}), col=#{colors}, c(#{series_names * ',' }),box.col=rgb(1,1,1,0), bg=rgb(1,1,1,0.75))
    """
  end
end