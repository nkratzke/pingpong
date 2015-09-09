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

# Implements the transferplot command.
#
def transferplot(args, options)
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
      xsteps: options.xsteps
  )

  script = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)

  print "#{ options.pdf.empty? ? rplot : script }"

  #R.eval(pdfout(rplot, file: options.pdf, width: options.width, height: options.height)) unless options.pdf.empty?
end

# Implements the lossplot command
#
def lossplot(args, options)

  options.default :machines => ''
  options.default :experiments => ''
  options.default :length => 500
  options.default :recwindow => 87380

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

  rplot = Ppbench::lossplotter(
      aggregated_data,
      to_plot: :transfer_rate,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      length: options.length * 1000,
      xsteps: options.xsteps
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
    machines.each { |machine, data| rows << [experiment, machine, data.count] }
    rows << :separator
  end

  print("We have data for: \n")
  table = Terminal::Table.new(:headings => ['Experiment', 'Machine', 'Data Points'], :rows => rows)
  table.align_column(2, :right)
  print("#{table}\n")
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

command :transferplot do |c|
  c.syntax = 'ppbench transferplot [options] *.csv'
  c.summary = 'Generates a R script to visualize benchmark data of ping pong experiments.'

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
    transferplot(args, options)
  end
end

command :lossplot do |c|
  c.syntax = 'ppbench lossplot [options] *.csv'
  c.summary = 'Generates a R script to visualize benchmark data of ping pong experiments.'

  c.option '--machines STRING', String, 'Generate R script for specific machines (e.g. m3.large, m3.xlarge, m3.2xlarge) comma separated'
  c.option '--experiments STRING', String, 'Generate R script for specific experiment (e.g. bare, docker, weave, flannel) comma separated'
  c.option '--length INTEGER', Integer, 'Maximum message size to consider in kB (e.g. 500). Defaults to 500kB.'
  c.option '--recwindow INTEGER', Integer, 'Standard Receive Window. Defaults to 87380 byte. (Receive Window is not plotted if set to 0.)'

  c.option '--xsteps INTEGER', Integer, '(defaults to 10)'

  c.option '--pdf FILE', String, 'Saves output to a PDF file'
  c.option '--width INTEGER', Integer, 'Width of plot in inch (defaults to 7 inch, only useful with PDF output)'
  c.option '--height INTEGER', Integer, 'Height of plot in inch (defaults to 7 inch, only useful with PDF output)'

  c.action do |args, options|
    lossplot(args, options)
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

