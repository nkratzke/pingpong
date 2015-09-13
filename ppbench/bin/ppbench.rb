#!/usr/bin/env ruby

require 'bundler/setup'
require 'rubygems'

require 'ppbench'
require 'commander/import'
require 'terminal-table'

program :name, 'ppbench'
program :version, "#{Ppbench::VERSION}"
program :description, 'Ping pong benchmark'
program :help, 'Author', 'Nane Kratzke <nane.kratzke@fh-luebeck.de>'

# Implements the run command.
#
def run(args, options)
  options.default :min => 1, :max => 500000
  options.default :machine => ''
  options.default :experiment => ''
  options.default :coverage => 0.01
  options.default :repetitions => 10
  options.default :concurrency => 1
  options.default :timeout => 60


  if (options.machine.empty?)
    print("You have to tag your benchmark data with the --machine option.\n")
    exit!
  end

  if (options.experiment.empty?)
    print("You have to tag your benchmark data with the --experiment option.\n")
    exit!
  end

  logfile = args[0]

  Ppbench::run_bench(
      options.host,
      logfile,
      machine_tag: options.machine,
      experiment_tag: options.experiment,
      coverage: options.coverage,
      min: options.min,
      max: options.max,
      concurrency: options.concurrency,
      repetitions: options.repetitions,
      timeout: options.timeout
  )
end

def pdfout(content, file: 'output.pdf', width: 7, height: 7)
  """
  pdf('#{file}', width=#{width}, height=#{height})
  #{content}
  dev.off()
  """
end

# Implements the transfer-plot command.
#
def transfer_plot(args, options)
  options.default :machines => ''
  options.default :experiments => ''
  options.default :length => 500
  options.default :recwindow => 87380
  options.default :confidence => 90

  options.default :maxy => 100000000
  options.default :ysteps => 10
  options.default :xsteps => 10

  options.default :pdf => ''
  options.default :width => 7
  options.default :height => 7

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      maxsize: options.length * 1000,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  rplot = Ppbench::plotter(
      aggregated_data,
      to_plot: :transfer_rate,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      length: options.length * 1000,
      confidence: options.confidence,
      no_points: options.nopoints,
      with_bands: options.withbands,
      maxy: options.maxy,
      ysteps: options.ysteps,
      xsteps: options.xsteps,
      title: "Data Transfer Rates",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      yaxis_title: "Transfer Rate",
      yaxis_unit: "MB/sec"
  )

  script = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)

  print "#{ options.pdf.empty? ? rplot : script }"

  #R.eval(pdfout(rplot, file: options.pdf, width: options.width, height: options.height)) unless options.pdf.empty?
end

# Implements the request-plot command.
#
def request_plot(args, options)
  options.default :machines => ''
  options.default :experiments => ''
  options.default :length => 5000
  options.default :recwindow => 87380
  options.default :confidence => 90

  options.default :maxy => 5000
  options.default :ysteps => 10
  options.default :xsteps => 10

  options.default :pdf => ''
  options.default :width => 7
  options.default :height => 7

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      maxsize: options.length * 1000,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  rplot = Ppbench::plotter(
      aggregated_data,
      to_plot: :rps,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      length: options.length * 1000,
      confidence: options.confidence,
      no_points: options.nopoints,
      with_bands: options.withbands,
      maxy: options.maxy,
      ysteps: options.ysteps,
      xsteps: options.xsteps,
      title: "Request per seconds",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      yaxis_title: "Requests per seconds",
      yaxis_unit: "Req/sec",
      yaxis_divisor: 1
  )

  script = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)

  print "#{ options.pdf.empty? ? rplot : script }"
end

# Implements the latency-plot command.
#
def latency_plot(args, options)
  options.default :machines => ''
  options.default :experiments => ''
  options.default :length => 500
  options.default :recwindow => 87380
  options.default :confidence => 90

  options.default :maxy => 50
  options.default :ysteps => 10
  options.default :xsteps => 10

  options.default :pdf => ''
  options.default :width => 7
  options.default :height => 7

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      maxsize: options.length * 1000,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  rplot = Ppbench::plotter(
      aggregated_data,
      to_plot: :tpr,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      length: options.length * 1000,
      confidence: options.confidence,
      no_points: options.nopoints,
      with_bands: options.withbands,
      maxy: options.maxy,
      ysteps: options.ysteps,
      xsteps: options.xsteps,
      title: "Round-trip latency",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      yaxis_title: "Latency",
      yaxis_unit: "ms",
      yaxis_divisor: 1
  )

  script = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)

  print "#{ options.pdf.empty? ? rplot : script }"
end


# Implements the transfer-comparison-plot command
#
def transfer_comparison_plot(args, options)

  options.default :machines => ''
  options.default :experiments => ''
  options.default :length => 500
  options.default :recwindow => 87380

  options.default :maxy => 1.5
  options.default :xsteps => 10

  options.default :pdf => ''
  options.default :width => 7
  options.default :height => 7

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      maxsize: options.length * 1000,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  rplot = Ppbench::comparison_plotter(
      aggregated_data,
      maxy: options.maxy,
      to_plot: :transfer_rate,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      length: options.length * 1000,
      xsteps: options.xsteps,
      title: "Relative Comparison of Data Transfer Rates",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      xaxis_divisor: 1000,
      yaxis_title: "Relative Performance compared with Reference"
  )

  script = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)
  print "#{ options.pdf.empty? ? rplot : script }"

end

# Implements the inspect command
#
def inspect_data(args, options)

  options.default :machines => ''
  options.default :experiments => ''

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  rows = []
  aggregated_data.each do |experiment, machines|
    machines.each do |machine, data|
      mtr = data.map { |e| e[:transfer_rate] }.median / 1000 # median transfer rate
      rps = 1000 / data.map { |e| e[:tpr] }.median           # median request per second
      rows << [experiment, machine, data.count, "%.2f" % mtr, "%.2f" % rps]
    end
    rows << :separator
  end
  rows.pop

  print("We have data for: \n")
  table = Terminal::Table.new(:headings => ['Experiment', 'Machine', 'Samples', 'Transfer Rate (kB/s)', "Requests/sec"], :rows => rows)
  table.align_column(2, :right)
  table.align_column(3, :right)
  table.align_column(4, :right)
  print("#{table}\n")
end

# Implements the citation command
#
def citation(args, options)

  bibtex =
  """
  @misc{Kra2015,
     title = {A distributed HTTP-based and REST-like ping-pong system for test and benchmarking purposes.},
     author = {{Nane Kratzke}},
     organization = {L\\\"ubeck University of Applied Sciences},
     address = {L\\\"ubeck, Germany},
     year = {2015},
     howpublished = {\\url{https://github.com/nkratzke/pingpong}}
  }
  """

  return bibtex if options.bibtex

  """
  To cite ppbench in publications use:

  Kratzke, Nane (2015). A distributed HTTP-based and REST-like ping-pong system for test and benchmarking purposes.
  L\\\"ubeck University of Applied Sciences, L\\\"ubeck, Germany. URL https://github.com/nkratzke/pingpong.

  A BibTeX entry for LaTeX users is: #{bibtex}

  """
end

command :run do |c|
  c.syntax = 'ppbench run [options] output.csv'
  c.description = 'Runs a ping pong benchmark'
  c.example 'Run a benchmark and tags the results as to be collected on a m3.2xlarge instance running a docker experiment',
            'ppbench run --host http://1.2.3.4:8080 --machine m3.2xlarge --experiment docker log.csv'

  c.option '--host STRING', String, 'Host'
  c.option '--machine STRING', String, 'A tag to categorize the machine (defaults to empty String)'
  c.option '--experiment STRING', String, 'A tag to categorize the experiment (defaults to empty String)'
  c.option '--min INTEGER', Integer, 'Minimum message size [bytes] (defaults to 1)'
  c.option '--max INTEGER', Integer, 'Maximum message size [bytes] (defaults to 500.000)'
  c.option '--coverage FLOAT', Float, 'Amount of test messages to send (defaults to 0.01)'
  c.option '--repetitions INTEGER', Integer, 'Repetitions for each data point to collect (defaults to 10)'
  c.option '--concurrency INTEGER', Integer, 'Concurrency level (defaults to 1)'
  c.option '--timeout INTEGER', Integer, 'Timeout in seconds (defaults to 60 seconds)'

  c.action do |args, options|
    run(args, options)
    print("Finished\n")
  end
end

command 'transfer-plot' do |c|
  c.syntax = 'ppbench transfer-plot [options] *.csv'
  c.summary = 'Generates a R script to plot data transfer rates of ping pong experiments.'

  c.option '--machines STRING', String, 'Generate R script for specific machines (e.g. m3.large, m3.xlarge, m3.2xlarge) comma separated'
  c.option '--experiments STRING', String, 'Generate R script for specific experiment (e.g. bare, docker, weave, flannel) comma separated'
  c.option '--length INTEGER', Integer, 'Maximum message size to consider in kB (e.g. 500). Defaults to 500kB.'
  c.option '--recwindow INTEGER', Integer, 'Standard Receive Window. Defaults to 87380 byte. (Receive Window is not plotted if set to 0.)'

  c.option '--maxy INTEGER', Integer, 'Maximum Y value on the Y axis (defaults to 100000000 == 100 MB/s)'
  c.option '--ysteps INTEGER', Integer, '(defaults to 10)'
  c.option '--xsteps INTEGER', Integer, '(defaults to 10)'

  c.option '--confidence INTEGER' , Integer, 'Percent value for confidence bands. Defaults to 90%.'
  c.option '--withbands', 'Plots confidence bands (confidence bands are _not_ plotted by default).'
  c.option '--nopoints', 'Show no points (points are plotted by default).'

  c.option '--pdf FILE', String, 'Saves output to a PDF file'
  c.option '--width INTEGER', Integer, 'Width of plot in inch (defaults to 7 inch, only useful with PDF output)'
  c.option '--height INTEGER', Integer, 'Height of plot in inch (defaults to 7 inch, only useful with PDF output)'


  c.action do |args, options|
    transfer_plot(args, options)
  end
end

command 'request-plot' do |c|
  c.syntax = 'ppbench request-plot [options] *.csv'
  c.summary = 'Generates a R script to plot requests per second of ping pong experiments.'

  c.option '--machines STRING', String, 'Generate R script for specific machines (e.g. m3.large, m3.xlarge, m3.2xlarge) comma separated'
  c.option '--experiments STRING', String, 'Generate R script for specific experiment (e.g. bare, docker, weave, flannel) comma separated'
  c.option '--length INTEGER', Integer, 'Maximum message size to consider in kB (e.g. 500). Defaults to 500kB.'
  c.option '--recwindow INTEGER', Integer, 'Standard Receive Window. Defaults to 87380 byte. (Receive Window is not plotted if set to 0.)'

  c.option '--maxy INTEGER', Integer, 'Maximum Y value on the Y axis (defaults to 5000 == 5000 Req/s)'
  c.option '--ysteps INTEGER', Integer, '(defaults to 10)'
  c.option '--xsteps INTEGER', Integer, '(defaults to 10)'

  c.option '--confidence INTEGER' , Integer, 'Percent value for confidence bands. Defaults to 90%.'
  c.option '--withbands', 'Plots confidence bands (confidence bands are _not_ plotted by default).'
  c.option '--nopoints', 'Show no points (points are plotted by default).'

  c.option '--pdf FILE', String, 'Saves output to a PDF file'
  c.option '--width INTEGER', Integer, 'Width of plot in inch (defaults to 7 inch, only useful with PDF output)'
  c.option '--height INTEGER', Integer, 'Height of plot in inch (defaults to 7 inch, only useful with PDF output)'


  c.action do |args, options|
    request_plot(args, options)
  end
end

command 'latency-plot' do |c|
  c.syntax = 'ppbench latency-plot [options] *.csv'
  c.summary = 'Generates a R script to plot round-trip latency of ping pong experiments.'

  c.option '--machines STRING', String, 'Generate R script for specific machines (e.g. m3.large, m3.xlarge, m3.2xlarge) comma separated'
  c.option '--experiments STRING', String, 'Generate R script for specific experiment (e.g. bare, docker, weave, flannel) comma separated'
  c.option '--length INTEGER', Integer, 'Maximum message size to consider in kB (e.g. 500). Defaults to 500kB.'
  c.option '--recwindow INTEGER', Integer, 'Standard Receive Window. Defaults to 87380 byte. (Receive Window is not plotted if set to 0.)'

  c.option '--maxy INTEGER', Integer, 'Maximum Y value on the Y axis (defaults to 500 ms)'
  c.option '--ysteps INTEGER', Integer, '(defaults to 10)'
  c.option '--xsteps INTEGER', Integer, '(defaults to 10)'

  c.option '--confidence INTEGER' , Integer, 'Percent value for confidence bands. Defaults to 90%.'
  c.option '--withbands', 'Plots confidence bands (confidence bands are _not_ plotted by default).'
  c.option '--nopoints', 'Show no points (points are plotted by default).'

  c.option '--pdf FILE', String, 'Saves output to a PDF file'
  c.option '--width INTEGER', Integer, 'Width of plot in inch (defaults to 7 inch, only useful with PDF output)'
  c.option '--height INTEGER', Integer, 'Height of plot in inch (defaults to 7 inch, only useful with PDF output)'


  c.action do |args, options|
    latency_plot(args, options)
  end
end



command 'transfer-comparison-plot' do |c|
  c.syntax = 'ppbench transfer-comparison-plot [options] *.csv'
  c.summary = 'Generates a R script to compare data transfer rates of ping pong experiments.'

  c.option '--maxy FLOAT', Float, 'Maximum Y Value (must be greater than 1.0, defaults to 1.5)'

  c.option '--machines STRING', String, 'Only consider specific machines (e.g. m3.large, m3.xlarge, m3.2xlarge) comma separated'
  c.option '--experiments STRING', String, 'Only consider specific experiments (e.g. bare, docker, weave, flannel) comma separated'
  c.option '--length INTEGER', Integer, 'Maximum message size to consider in kB (e.g. 500). Defaults to 500kB.'
  c.option '--recwindow INTEGER', Integer, 'Standard Receive Window. Defaults to 87380 byte. (Receive Window is not plotted if set to 0.)'

  c.option '--xsteps INTEGER', Integer, '(defaults to 10)'

  c.option '--pdf FILE', String, 'Saves output to a PDF file'
  c.option '--width INTEGER', Integer, 'Width of plot in inch (defaults to 7 inch, only useful with PDF output)'
  c.option '--height INTEGER', Integer, 'Height of plot in inch (defaults to 7 inch, only useful with PDF output)'

  c.action do |args, options|
    transfer_comparison_plot(args, options)
  end
end

command :inspect do |c|
  c.syntax = 'ppbench inspect [options] *.csv'
  c.summary = 'Inspects benchmark data.'

  c.example 'Inspects and lists a summary of all benchmark data.',
            'ppbench inspect *.csv'
  c.example 'Inspects and lists a summary of all benchmark data tagged to be run on machines m3.2xlarge, m3.xlarge',
            'ppbench inspect --machines m3.2xlarge,m3.xlarge *.csv'
  c.example 'Inspects and lists a summary of all benchmark data tagged to be run as docker-java or bare-dart experiments',
            'ppbench inspect --experiments bare-dart,docker-java *.csv'

  c.option '--machines STRING', String, 'Consider only data of provided machines (comma separated)'
  c.option '--experiments STRING', String, 'Consider only data of provided experiments (comma separated)'

  c.action do |args, options|
    inspect_data(args, options)
  end
end

command :citation do |c|
  c.syntax = 'ppbench citation [options]'
  c.summary = 'Provides information how to cite ppbench in publications.'

  c.example 'Get general information how to cite ppbench in publications',
            'ppbench citation'
  c.example 'Append a bibtex entry to cite ppbench in publications (LaTex Users) to your references.bib',
            'ppbench citation --bibtex >> references.bib'
  c.option  '--bibtex', 'Get bibtex entry (for Latex users)'

  c.action do |args, options|
    print citation(args, options)
  end
end

