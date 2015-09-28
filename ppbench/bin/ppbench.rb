#!/usr/bin/env ruby

require 'ppbench'
require 'commander/import'
require 'terminal-table'
require 'json'

# Description constants used by the help command.
#
MACHINES_DESCRIPTION     = 'Consider only specific machines (e.g. m3.large,m3.xlarge); comma separated list.'
EXPERIMENTS_DESCRIPTION  = 'Consider only specific experiments (e.g. bare,docker,weave); comma separated list.'
RECWINDOW_DESCRIPTION    = 'Standard Receive Window. Defaults to 87380 byte (Window is not plotted if set to 0).'
YAXIS_MAX_DESCRIPTION    = 'Maximum Y value on the Y axis (defaults to biggest value found).'
YAXIS_STEPS_DESCRIPTION  = 'How many ticks shall be plotted on yaxis (defaults to 10).'
XAXIS_MAX_DESCRIPTION    = 'Maximum X value on the X axis (defaults to biggest message size found).'
XAXIS_STEPS_DESCRIPTION  = 'How many ticks shall be plotted on xaxis (defaults to 10).'
PRECISION_DESCRIPTION    = 'Amount of points used per series for plotting medians, comparisons and confidence intervals.'
CONFIDENCE_DESCRIPTION   = 'Percent value for confidence bands. Defaults to 90%.'
WITHBANDS_DESCRIPTION    = 'Plots confidence bands (confidence bands are _not_ plotted by default).'
NOPOINTS_DESCRIPTION     = 'Show no points (points are plotted by default).'
NAMING_DESCRIPTION       = 'Use user defined names via an JSON file.'
ALPHA_DESCRIPTION        = "Transparency (alpha) for points of scatter plots (defaults to 0.05, must be between 0.0 and 1.0)"
PDF_DESCRIPTION          = 'Adds additional commands to an R script, so that it can be used to generate a PDF file.'
PDF_WIDTH_DESCRIPTION    = 'Width of plot in inch (defaults to 7 inch, only useful with PDF output).'
PDF_HEIGHT_DESCRIPTION   = 'Height of plot in inch (defaults to 7 inch, only useful with PDF output).'

# Plotting constants used for plotting.
#
RECWINDOW_DEFAULT        = 87380
CONFIDENCE_DEFAULT       = 90
AXIS_STEP_DEFAULT        = 10
COMPARISON_MAX_DEFAULT   = 2.0

# Constants used for PDF generation.
#
PDF_HEIGHT_WIDTH_DEFAULT = 7

program :name, 'ppbench'
program :version, "#{Ppbench::VERSION}"
program :description, 'Ping pong benchmark'
program :help, 'Author', 'Nane Kratzke <nane.kratzke@fh-luebeck.de>'

global_option '--precision POINTS', Integer, PRECISION_DESCRIPTION
global_option '--naming FILE', String, NAMING_DESCRIPTION
global_option '--alpha FLOAT', Float, ALPHA_DESCRIPTION

default_command :help

# Validates and processes global options like
# - precision (used for comparison lines, median lines and confidence band plotting)
# - naming (used for user defined naming of machine and experiment tags)
#
def validate_global_options(args, options)
  options.default :precision => 500
  options.default :naming => ''
  options.default :alpha => 0.05

  if options.precision < 20
    $stderr.puts("Error in --precision flag: Precision must be >= 20 points.\n")
    exit!
  end

  if options.precision < 0
    $stderr.puts("Error in --precision flag: Precision must be >= 1 point.\n")
    exit!
  end

  Ppbench::precision = options.precision

  if !options.naming.empty? && !File.exist?(options.naming)
    $stderr.puts("Error in --naming flag: File '#{options.naming}' does not exist.")
    exit!
  end

  Ppbench::naming = {} if options.naming.empty?

  unless options.naming.empty?
    begin
      file = File.read(options.naming)
      Ppbench::naming = JSON.parse(file)
    rescue Exception => ex
      $stderr.puts("Error in naming file '#{options.naming}'. Does not seem to be a valid JSON file.")
      exit!
    end
  end

  if options.alpha < 0.0 || options.alpha > 1.0
    $stderr.puts("Error in --alpha flag: Alpha must be between 0.0 and 1.0, but alpha was '#{options.alpha}'.")
    exit!
  end

  Ppbench::alpha = options.alpha
end

# Validates command line flags of the run command.
#
def validate_run_options(args, options)

  if (options.machine.empty?)
    $stderr.puts("You have to tag your benchmark data with the --machine flag.\n")
    exit!
  end

  if (options.experiment.empty?)
    $stderr.puts("You have to tag your benchmark data with the --experiment flag.\n")
    exit!
  end

  if options.coverage < 0 || options.coverage > 1.0
    $stderr.puts("Error in --coverage flag: Coverage must be in [0..1.0]\n")
    exit!
  end

  if options.repetitions < 1
    $stderr.puts("Error in --repetitions flag: Repetitions must be >= 1\n")
    exit!
  end

  if options.concurrency < 1
    $stderr.puts("Error in --concurrency flag: Concurrency must be >= 1\n")
    exit!
  end

  if options.timeout < 1
    $stderr.puts("Error in --timeout flag: Timeout must be >= 1 seconds\n")
    exit!
  end

  if args.empty?
    $stderr.puts("You have to specify a log file.\n")
    exit!
  end

  if args.length > 1
    $stderr.puts("You should only specify one log file. You specified #{args.length} logfiles.\n")
    exit!
  end

  if File.exist?(args[0])
    $stderr.puts("Logfile #{args[0]} already exists. You do not want to overwrite collected benchmark data.\n")
    exit!
  end

end

# Validates command line flags of the xyz-comparison-plot commands.
#
def validate_comparison_options(args, options)

  if args.empty?
    $stderr.puts("You have to provide benchmark files (*.csv) to analyze.")
    exit!
  end

  if options.recwindow < 0
    $stderr.puts("Error in --recwindow flag: TCP standard receive window must be >= 0 bytes.\n")
    exit!
  end

  if options.yaxis_max < 0
    $stderr.puts("Error in --yaxis_max flag: Maximum value on yaxis must be >= 0.\n")
  end

  if options.xaxis_max < 0
    $stderr.puts("Error in --xaxis_max flag: Maximum value on xaxis must be >= 0.\n")
    exit!
  end

  if options.xaxis_steps <= 0
    $stderr.puts("Error in --xaxis_steps flag: You must provide a positive step > 0.\n")
    exit!
  end

end

# Validates command line flags of the xyz-plot commands.
#
def validate_plot_options(args, options)

  if args.empty?
    $stderr.puts("You have to provide benchmark files (*.csv) to analyze.")
    exit!
  end

  if options.recwindow < 0
    $stderr.puts("Error in --recwindow flag: TCP standard receive window must be >= 0 bytes\n")
    exit!
  end

  if options.confidence < 0 || options.confidence > 100
    $stderr.puts("Error in --confidence flag: Confidence interval must be between 0 and 100 %.\n")
    exit!
  end

  if options.yaxis_max < 0
    $stderr.puts("Error in --yaxis_max flag: Maximum value on yaxis must be >= 0.\n")
  end

  if options.yaxis_steps <= 0
    $stderr.puts("Error in --yaxis_steps flag: You must provide a positive step > 0.\n")
    exit!
  end

  if options.xaxis_max < 0
    $stderr.puts("Error in --xaxis_max flag: Maximum value on xaxis must be >= 0.\n")
    exit!
  end

  if options.xaxis_steps <= 0
    $stderr.puts("Error in --xaxis_steps flag: You must provide a positive step > 0.\n")
    exit!
  end

  if options.nopoints && !options.withbands
    $stderr.puts("Error in --nopoints flag. You must use --withbands if applying --nopoints. Otherwise nothing would be plotted.\n")
    exit!
  end

end

# Validates command line options dealing with PDF generation.
#
def validate_pdf_options(args, options)
  if options.height < 1
    $stderr.puts("Error in --height flag. You must provide a positive height >= 1 in inch.\n")
    exit!
  end

  if options.width < 1
    $stderr.puts("Error in --width flag. You must provide a positive width >= 1 in inch.\n")
    exit!
  end
end

# Validates command line options for the naming-template command.
#
def validate_naming_options(args, options)
  if args.empty?
    $stderr.puts("Error due to missing files to analyze. You must provide at least one log file (csv).\n")
    exit!
  end

  if !options.update.empty? && !File.exist?(options.update)
    $stderr.puts("Error: File #{options.update} does not exist.\n")
    exit!
  end
end

# Implements the run command.
#
def run(args, options)

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

# Embeds a R script (content) into some PDF generating
# R statements.
#
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

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  max_x = Ppbench::maximum(aggregated_data, of: :length)
  max_y = Ppbench::maximum(aggregated_data, of: :transfer_rate)

  rplot = Ppbench::plotter(
      aggregated_data,
      to_plot: :transfer_rate,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      xaxis_max: options.xaxis_max == 0 ? max_x : options.xaxis_max,
      confidence: options.confidence,
      no_points: options.nopoints,
      with_bands: options.withbands,
      yaxis_max: options.yaxis_max == 0 ? max_y : options.yaxis_max,
      yaxis_steps: options.yaxis_steps,
      xaxis_steps: options.xaxis_steps,
      title: "Data Transfer Rates",
      subtitle: "bigger is better",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      yaxis_title: "Transfer Rate",
      yaxis_unit: "MB/sec"
  )

  pdf = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)
  print("#{pdf}") unless options.pdf.empty?
  print("#{rplot}") if options.pdf.empty?
end

# Implements the transfer-comparison-plot command.
#
def transfer_comparison_plot(args, options)

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  max_x = Ppbench::maximum(aggregated_data, of: :length)

  rplot = Ppbench::comparison_plotter(
      aggregated_data,
      yaxis_max: options.yaxis_max,
      to_plot: :transfer_rate,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      xaxis_max: options.xaxis_max == 0 ? max_x : options.xaxis_max,
      xaxis_steps: options.xaxis_steps,
      title: "Data transfer in relative comparison",
      subtitle: "bigger is better",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      xaxis_divisor: 1000,
      yaxis_title: "Ratio"
  )

  pdf = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)
  print("#{pdf}") unless options.pdf.empty?
  print("#{rplot}") if options.pdf.empty?

end

# Implements the request-plot command.
#
def request_plot(args, options)

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  max_x = Ppbench::maximum(aggregated_data, of: :length)
  max_y = Ppbench::maximum(aggregated_data, of: :rps)

  rplot = Ppbench::plotter(
      aggregated_data,
      to_plot: :rps,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      xaxis_max: options.xaxis_max == 0 ? max_x : options.xaxis_max,
      confidence: options.confidence,
      no_points: options.nopoints,
      with_bands: options.withbands,
      yaxis_max: options.yaxis_max == 0 ? max_y : options.yaxis_max,
      yaxis_steps: options.yaxis_steps,
      xaxis_steps: options.xaxis_steps,
      title: "Requests per seconds",
      subtitle: "bigger is better",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      yaxis_title: "Requests per seconds",
      yaxis_unit: "Req/sec",
      yaxis_divisor: 1
  )

  pdf = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)
  print("#{pdf}") unless options.pdf.empty?
  print("#{rplot}") if options.pdf.empty?
end

# Implements the request-comparison-plot command
#
def request_comparison_plot(args, options)

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  max_x = Ppbench::maximum(aggregated_data, of: :length)

  rplot = Ppbench::comparison_plotter(
      aggregated_data,
      yaxis_max: options.yaxis_max,
      to_plot: :rps,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      xaxis_max: options.xaxis_max == 0 ? max_x : options.xaxis_max,
      xaxis_steps: options.xaxis_steps,
      title: "Requests per second in relative comparison",
      subtitle: "bigger is better",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      xaxis_divisor: 1000,
      yaxis_title: "Ratio",
  )

  pdf = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)
  print("#{pdf}") unless options.pdf.empty?
  print("#{rplot}") if options.pdf.empty?
end

# Implements the latency-plot command.
#
def latency_plot(args, options)

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  max_y = Ppbench::maximum(aggregated_data, of: :tpr)
  max_x = Ppbench::maximum(aggregated_data, of: :length)

  rplot = Ppbench::plotter(
      aggregated_data,
      to_plot: :tpr,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      xaxis_max: options.xaxis_max == 0 ? max_x : options.xaxis_max,
      confidence: options.confidence,
      no_points: options.nopoints,
      with_bands: options.withbands,
      yaxis_max: options.yaxis_max == 0 ? max_y : options.yaxis_max,
      yaxis_steps: options.yaxis_steps,
      xaxis_steps: options.xaxis_steps,
      title: "Round-trip latency",
      subtitle: "smaller is better",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      yaxis_title: "Latency",
      yaxis_unit: "ms",
      yaxis_divisor: 1
  )

  pdf = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)
  print("#{pdf}") unless options.pdf.empty?
  print("#{rplot}") if options.pdf.empty?
end

# Implements the latency-comparison-plot command
#
def latency_comparison_plot(args, options)

  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )
  aggregated_data = Ppbench::aggregate(filtered_data)

  max_x = Ppbench::maximum(aggregated_data, of: :length)

  rplot = Ppbench::comparison_plotter(
      aggregated_data,
      yaxis_max: options.yaxis_max,
      to_plot: :tpr,
      machines: machines,
      experiments: experiments,
      receive_window: options.recwindow,
      xaxis_max: options.xaxis_max == 0 ? max_x : options.xaxis_max,
      xaxis_steps: options.xaxis_steps,
      title: "Round-trip latency in relative comparison",
      subtitle: "smaller is better",
      xaxis_title: "Message Size",
      xaxis_unit: "kB",
      xaxis_divisor: 1000,
      yaxis_title: "Ratio",
  )

  pdf = pdfout(rplot, file: options.pdf, width: options.width, height: options.height)
  print("#{pdf}") unless options.pdf.empty?
  print("#{rplot}") if options.pdf.empty?
end

# Implements the summary command.
#
def summary(args, options)

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
      tpr = data.map { |e| e[:tpr] }.median                  # median round trip latency
      rps = 1000 / tpr                                       # median request per second

      rows << [experiment, machine, data.count, "%.2f" % mtr, "%.2f" % rps, "%.2f" % tpr]
    end
    rows << :separator
  end
  rows.pop

  print("We have data for: \n")
  table = Terminal::Table.new(:headings => ['Experiment', 'Machine', 'Samples', 'Transfer (kB/s)', "Requests/sec", "Latency (ms)"], :rows => rows)
  table.align_column(2, :right)
  table.align_column(3, :right)
  table.align_column(4, :right)
  table.align_column(5, :right)
  print("#{table}\n")
end

# Implements the naming command.
#
def naming(args, options)
  experiments = options.experiments.split(',')
  machines = options.machines.split(',')

  data = Ppbench::load_data(args)
  filtered_data = Ppbench::filter(
      data,
      experiments: experiments,
      machines: machines
  )

  json_to_update = {}
  existing_machine_names = []
  existing_experiment_names = []
  unless options.update.empty?
    begin
      file = File.read(options.update)
      json_to_update = JSON.parse(file)
    rescue Exception => ex
      $stderr.puts("Could not process #{options.update}. It does not seem to be a valid JSON file.")
      exit!
    end
  end

  existing_machine_names = json_to_update['machines'].keys if json_to_update['machines']
  existing_experiment_names = json_to_update['experiments'].keys if json_to_update['experiments']

  machine_names = filtered_data.map { |entry| entry[:machine] }.uniq.sort - existing_machine_names
  experiment_names = filtered_data.map { |entry| entry[:experiment] }.uniq.sort - existing_experiment_names

  machines_map = (
    machine_names.map { |e| [e, "#{e} (TODO: Provide a better name)"] } +
    existing_machine_names.map { |e| [e, json_to_update['machines'][e]] }
  ).to_h

  experiments_map = (
    experiment_names.map { |e| [e, "#{e} (TODO: Provide a better name)"] } +
    existing_experiment_names.map { |e| [e, json_to_update['experiments'][e]] }
  ).to_h

  json = { "machines": machines_map, "experiments": experiments_map }
  print ("#{JSON.pretty_generate(json)}")
end

# Implements the citation command.
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
  Lübeck University of Applied Sciences, Lübeck, Germany. URL https://github.com/nkratzke/pingpong.

  A BibTeX entry for LaTeX users is: #{bibtex}

  """
end

command :run do |c|
  c.syntax = 'ppbench run [options] log.csv'
  c.description = 'Runs a ping pong benchmark.'
  c.example 'Run a benchmark and tags the results as to be collected on a m3.2xlarge instance running a docker experiment',
            'ppbench run --host http://1.2.3.4:8080 --machine m3.2xlarge --experiment docker log.csv'

  c.option '--host STRING',       String,  'Host'
  c.option '--machine STRING',    String,  'A tag to categorize the machine (defaults to empty String)'
  c.option '--experiment STRING', String,  'A tag to categorize the experiment (defaults to empty String)'
  c.option '--min INT',           Integer, 'Minimum message size [bytes] (defaults to 1)'
  c.option '--max INT',           Integer, 'Maximum message size [bytes] (defaults to 500.000)'
  c.option '--coverage FLOAT',    Float,   'Amount of requests to send (defaults to 5% == 0.05, must be between 0.0 and 1.0)'
  c.option '--repetitions INT',   Integer, 'Repetitions for each data point to collect (defaults to 1, must be >= 1)'
  c.option '--concurrency INT',   Integer, 'Requests to be send at the same time in parallel (defaults to 1, must be >= 1)'
  c.option '--timeout SECONDS',   Integer, 'Timeout in seconds (defaults to 60 seconds, must be >= 1)'

  c.action do |args, options|

    options.default :min => 1, :max => 500000
    options.default :machine => ''
    options.default :experiment => ''
    options.default :coverage => 0.05
    options.default :repetitions => 1
    options.default :concurrency => 1
    options.default :timeout => 60

    validate_global_options(args, options)
    validate_run_options(args, options)
    run(args, options)
    print("Finished\n")
  end
end

command 'transfer-plot' do |c|
  c.syntax = 'ppbench transfer-plot [options] *.csv'
  c.summary = 'Plots data transfer rates in an absolute way.'
  c.description = 'Generates a R script to plot data transfer rates in an absolute way.'

  c.option '--machines LIST', String, MACHINES_DESCRIPTION
  c.option '--experiments LIST', String, EXPERIMENTS_DESCRIPTION
  c.option '--recwindow BYTES', Integer, RECWINDOW_DESCRIPTION

  c.option '--yaxis_max FLOAT', Float, YAXIS_MAX_DESCRIPTION
  c.option '--yaxis_steps TICKS', Integer, YAXIS_STEPS_DESCRIPTION
  c.option '--xaxis_max BYTES', Integer, YAXIS_MAX_DESCRIPTION
  c.option '--xaxis_steps TICKS', Integer, XAXIS_STEPS_DESCRIPTION

  c.option '--confidence PERCENT' , Integer, CONFIDENCE_DESCRIPTION
  c.option '--withbands', WITHBANDS_DESCRIPTION
  c.option '--nopoints', NOPOINTS_DESCRIPTION

  c.option '--pdf FILE', String, PDF_DESCRIPTION
  c.option '--width INCH', Integer, PDF_WIDTH_DESCRIPTION
  c.option '--height INCH', Integer, PDF_HEIGHT_DESCRIPTION

  c.action do |args, options|
    options.default :machines => ''
    options.default :experiments => ''
    options.default :recwindow => RECWINDOW_DEFAULT
    options.default :confidence => CONFIDENCE_DEFAULT

    options.default :yaxis_max => 0
    options.default :yaxis_steps => AXIS_STEP_DEFAULT
    options.default :xaxis_max => 0
    options.default :xaxis_steps => AXIS_STEP_DEFAULT

    options.default :pdf => ''
    options.default :width => PDF_HEIGHT_WIDTH_DEFAULT
    options.default :height => PDF_HEIGHT_WIDTH_DEFAULT

    validate_global_options(args, options)
    validate_plot_options(args, options)
    validate_pdf_options(args,options)
    transfer_plot(args, options)
  end
end


command 'transfer-comparison-plot' do |c|
  c.syntax = 'ppbench transfer-comparison-plot [options] *.csv'
  c.summary = 'Compares data transfer rates in a relative way.'
  c.description = 'Generates a R script to compare data transfer rates in a relative way.'

  c.option '--machines LIST', String, MACHINES_DESCRIPTION
  c.option '--experiments LIST', String, EXPERIMENTS_DESCRIPTION
  c.option '--recwindow BYTES', Integer, RECWINDOW_DESCRIPTION

  c.option '--yaxis_max BYTES', Float, YAXIS_MAX_DESCRIPTION
  c.option '--yaxis_steps STEPS', Integer, YAXIS_STEPS_DESCRIPTION
  c.option '--xaxis_max BYTES', Integer, XAXIS_MAX_DESCRIPTION
  c.option '--xaxis_steps STEPS', Integer, XAXIS_STEPS_DESCRIPTION

  c.option '--pdf FILE', String, PDF_DESCRIPTION
  c.option '--width INTEGER', Integer, PDF_WIDTH_DESCRIPTION
  c.option '--height INTEGER', Integer, PDF_HEIGHT_DESCRIPTION

  c.action do |args, options|

    options.default :machines => ''
    options.default :experiments => ''
    options.default :recwindow => RECWINDOW_DEFAULT

    options.default :yaxis_max => COMPARISON_MAX_DEFAULT
    options.default :yaxis_steps => AXIS_STEP_DEFAULT
    options.default :xaxis_max => 0
    options.default :xaxis_steps => AXIS_STEP_DEFAULT

    options.default :pdf => ''
    options.default :width => PDF_HEIGHT_WIDTH_DEFAULT
    options.default :height => PDF_HEIGHT_WIDTH_DEFAULT

    validate_global_options(args, options)
    validate_comparison_options(args, options)
    validate_pdf_options(args,options)
    transfer_comparison_plot(args, options)
  end
end

command 'request-plot' do |c|
  c.syntax = 'ppbench request-plot [options] *.csv'
  c.summary = 'Plots requests per second in an absolute way.'
  c.description = 'Generates a R script to plot requests per second in an absolute way.'

  c.option '--machines LIST', String, MACHINES_DESCRIPTION
  c.option '--experiments LIST', String, EXPERIMENTS_DESCRIPTION
  c.option '--recwindow BYTES', Integer, RECWINDOW_DESCRIPTION

  c.option '--yaxis_max REQS', Float, YAXIS_MAX_DESCRIPTION
  c.option '--yaxis_steps STEPS', Integer, YAXIS_STEPS_DESCRIPTION
  c.option '--xaxis_max BYTES', Integer, XAXIS_MAX_DESCRIPTION
  c.option '--xsteps STEPS', Integer, YAXIS_STEPS_DESCRIPTION

  c.option '--confidence PERCENT' , Integer, CONFIDENCE_DESCRIPTION
  c.option '--withbands', WITHBANDS_DESCRIPTION
  c.option '--nopoints', NOPOINTS_DESCRIPTION

  c.option '--pdf FILE', String, PDF_DESCRIPTION
  c.option '--width INCH', Integer, PDF_WIDTH_DESCRIPTION
  c.option '--height INCH', Integer, PDF_HEIGHT_DESCRIPTION

  c.action do |args, options|
    options.default :machines => ''
    options.default :experiments => ''
    options.default :recwindow => RECWINDOW_DEFAULT
    options.default :confidence => CONFIDENCE_DEFAULT

    options.default :yaxis_max => 0
    options.default :yaxis_steps => AXIS_STEP_DEFAULT
    options.default :xaxis_max => 0
    options.default :xaxis_steps => AXIS_STEP_DEFAULT

    options.default :pdf => ''
    options.default :width => PDF_HEIGHT_WIDTH_DEFAULT
    options.default :height => PDF_HEIGHT_WIDTH_DEFAULT

    validate_global_options(args, options)
    validate_plot_options(args, options)
    validate_pdf_options(args, options)
    request_plot(args, options)
  end
end

command 'request-comparison-plot' do |c|
  c.syntax = 'ppbench request-comparison-plot [options] *.csv'
  c.summary = 'Compares requests per second in a relative way.'
  c.description = 'Generates a R script to compare requests per second in a relative way.'

  c.option '--machines STRING', String, MACHINES_DESCRIPTION
  c.option '--experiments STRING', String, EXPERIMENTS_DESCRIPTION
  c.option '--recwindow INTEGER', Integer, RECWINDOW_DESCRIPTION

  c.option '--yaxis_max FLOAT', Float, YAXIS_MAX_DESCRIPTION

  c.option '--xaxis_max BYTES', Integer, XAXIS_MAX_DESCRIPTION
  c.option '--xaxis_steps INTEGER', Integer, YAXIS_STEPS_DESCRIPTION

  c.option '--pdf FILE', String, 'Saves output to a PDF file'
  c.option '--width INTEGER', Integer, 'Width of plot in inch (defaults to 7 inch, only useful with PDF output)'
  c.option '--height INTEGER', Integer, 'Height of plot in inch (defaults to 7 inch, only useful with PDF output)'

  c.action do |args, options|

    options.default :machines => ''
    options.default :experiments => ''
    options.default :recwindow => RECWINDOW_DEFAULT

    options.default :yaxis_max => COMPARISON_MAX_DEFAULT
    options.default :xaxis_max => 0
    options.default :xaxis_steps => AXIS_STEP_DEFAULT

    options.default :pdf => ''
    options.default :width => PDF_HEIGHT_WIDTH_DEFAULT
    options.default :height => PDF_HEIGHT_WIDTH_DEFAULT

    validate_global_options(args, options)
    validate_comparison_options(args, options)
    validate_pdf_options(args, options)
    request_comparison_plot(args, options)
  end
end

command 'latency-plot' do |c|
  c.syntax  = 'ppbench latency-plot [options] *.csv'
  c.summary = 'Plots round-trip latencies in an absolute way.'
  c.description = 'Generates a R script to plot round-trip latencies in an absolute way.'

  c.example 'Generates a latency plot for data collected on machine m3.xlarge for java, dart and go implementations of the ping-pong system.',
            'ppbench latency-plot --machines m3.xlarge --experiments bare-java,bare-go,bare-dart *.csv > bare-comparison.R'

  c.example 'Generates a latency plot for data collected on machine m3.xlarge for java, dart implementations of the ping-pong system.',
            'ppbench latency-comparison-plot --machines m3.xlarge --experiments bare-java,bare-go --pdf compare.pdf --width 9, --height 6 *.csv > bare-comparison.R'

  c.option '--machines LIST', String, MACHINES_DESCRIPTION
  c.option '--experiments LIST', String, EXPERIMENTS_DESCRIPTION
  c.option '--recwindow BYTES', Integer, RECWINDOW_DESCRIPTION

  c.option '--yaxis_max MS', Integer, YAXIS_MAX_DESCRIPTION
  c.option '--yaxis_steps TICKS', Integer, YAXIS_STEPS_DESCRIPTION
  c.option '--xaxis_max BYTES', Integer, XAXIS_MAX_DESCRIPTION
  c.option '--xaxis_steps TICKS', Integer, XAXIS_STEPS_DESCRIPTION

  c.option '--confidence PERCENT' , Integer, CONFIDENCE_DESCRIPTION
  c.option '--withbands', WITHBANDS_DESCRIPTION
  c.option '--nopoints', NOPOINTS_DESCRIPTION

  c.option '--pdf FILE', String, PDF_DESCRIPTION
  c.option '--width INCH', Integer, PDF_WIDTH_DESCRIPTION
  c.option '--height INCH', Integer, PDF_HEIGHT_DESCRIPTION

  c.action do |args, options|

    options.default :machines => ''
    options.default :experiments => ''
    options.default :recwindow => RECWINDOW_DEFAULT

    options.default :confidence => CONFIDENCE_DEFAULT

    options.default :yaxis_max => 0
    options.default :yaxis_steps => AXIS_STEP_DEFAULT
    options.default :xaxis_max => 0
    options.default :xaxis_steps => AXIS_STEP_DEFAULT

    options.default :pdf => ''
    options.default :width => PDF_HEIGHT_WIDTH_DEFAULT
    options.default :height => PDF_HEIGHT_WIDTH_DEFAULT

    validate_global_options(args, options)
    validate_plot_options(args, options)
    validate_pdf_options(args, options)
    latency_plot(args, options)
  end
end

command 'latency-comparison-plot' do |c|
  c.syntax  = 'ppbench latency-comparison-plot [options] *.csv'
  c.summary = 'Compares round-trip latencies in a relative way.'
  c.description = 'Generates a R script to compare round-trip latencies in a relative way.'

  c.example 'Generates a latency comparison plot for data collected on machine m3.xlarge for java, dart and go implementations of the ping-pong system.',
            'ppbench latency-comparison-plot --machines m3.xlarge --experiments bare-java,bare-go,bare-dart *.csv > bare-comparison.R'

  c.example 'Generates a latency comparison plot as PDF using Rscript',
            'ppbench latency-comparison-plot -m m3.xlarge -e bare-java,bare-go -p compare.pdf *.csv | Rscript - '

  c.option '--machines LIST', String, MACHINES_DESCRIPTION
  c.option '--experiments LIST', String, EXPERIMENTS_DESCRIPTION
  c.option '--recwindow BYTES', Integer, RECWINDOW_DESCRIPTION

  c.option '--yaxis_max MS', Float, 'Maximum Y Value (must be greater than 1.0, defaults to 2.0)'
  c.option '--xaxis_max BYTES', Integer, XAXIS_MAX_DESCRIPTION
  c.option '--xaxis_steps TICKS', Integer, YAXIS_STEPS_DESCRIPTION

  c.option '--pdf FILE', String, PDF_DESCRIPTION
  c.option '--width INCH', Integer, PDF_WIDTH_DESCRIPTION
  c.option '--height INCH', Integer, PDF_HEIGHT_DESCRIPTION

  c.action do |args, options|

    options.default :machines => ''
    options.default :experiments => ''
    options.default :recwindow => RECWINDOW_DEFAULT

    options.default :yaxis_max => COMPARISON_MAX_DEFAULT
    options.default :xaxis_max => 0
    options.default :xaxis_steps => AXIS_STEP_DEFAULT

    options.default :pdf => ''
    options.default :width => PDF_HEIGHT_WIDTH_DEFAULT
    options.default :height => PDF_HEIGHT_WIDTH_DEFAULT

    validate_global_options(args, options)
    validate_comparison_options(args, options)
    validate_pdf_options(args, options)
    latency_comparison_plot(args, options)
  end
end

command :summary do |c|
  c.syntax = 'ppbench summary [options] *.csv'
  c.summary = 'Summarizes benchmark data.'
  c.description = 'Summarizes benchmark data. Useful to inspect data for completeness or to query machine and experiment tags.'

  c.example 'Lists a summary of all benchmark data.',
            'ppbench summary *.csv'
  c.example 'Lists a summary of all benchmark data tagged to be run on machines m3.2xlarge, m3.xlarge',
            'ppbench summary --machines m3.2xlarge,m3.xlarge *.csv'
  c.example 'Lists a summary of all benchmark data tagged to be run as docker-java or bare-dart experiments',
            'ppbench summary --experiments bare-dart,docker-java *.csv'

  c.option '--machines LIST', String, MACHINES_DESCRIPTION
  c.option '--experiments LIST', String, EXPERIMENTS_DESCRIPTION

  c.action do |args, options|
    options.default :machines => ''
    options.default :experiments => ''

    summary(args, options)
  end
end

command 'naming-template' do |c|

  c.syntax = 'ppbench naming-template [options] *.csv'
  c.summary = 'Generates a JSON file for naming.'
  c.description = 'Generates a JSON file from benchmark data for naming. This file can be used with the --naming flag.'

  c.example 'Generates a naming template from all benchmark data.',
            'ppbench naming-template *.csv > naming.json'
  c.example 'Appends all missing names to an existing naming-template',
            'ppbench naming-template --update naming.json > naming-update.json'

  c.option '--machines LIST', String, MACHINES_DESCRIPTION
  c.option '--experiments LIST', String, EXPERIMENTS_DESCRIPTION
  c.option '--update FILE', 'Naming file to update with additional data.'

  c.action do |args, options|
    options.default :machines => ''
    options.default :experiments => ''
    options.default :update => ''

    validate_naming_options(args, options)
    naming(args, options)
  end

end

command :citation do |c|
  c.syntax = 'ppbench citation [options]'
  c.summary = 'Citation information about ppbench.'
  c.description = 'Provides information how to cite ppbench in publications.'

  c.example 'Get general information how to cite ppbench in publications',
            'ppbench citation'
  c.example 'Append a bibtex entry for ppbench to your references.bib (LaTex users).',
            'ppbench citation --bibtex >> references.bib'
  c.option  '--bibtex', 'Get bibtex entry (for Latex users)'

  c.action do |args, options|
    print "#{citation(args, options)}\n"
  end
end