import 'package:args/args.dart';
import 'dart:io';
import 'dart:async';

/**
 * Extracts log data from a apache bench run.
 * Tags this data with a tag.
 * Returns a csv line.
 */
String extractAndTagData(String log, String tag) {
  // Each benchmark log entry starts with "This is ApacheBench"
  if (log.isEmpty) return ""; // Skip to first empty entry

  // Reduce benchmark log to relevant data
  final lines = log.split("\n").where((line) =>
    line.startsWith("Document Path:") ||
    line.startsWith("Document Length:") ||
    line.startsWith("Time taken for tests:") ||
    line.startsWith("Complete requests:") ||
    line.startsWith("Failed requests:") ||
    line.startsWith("Concurrency Level:") ||
    line.startsWith("Total transferred:") ||
    line.startsWith("Requests per second:") ||
    line.startsWith("Transfer rate:")
  );

  if (lines.isEmpty) return ""; // Skip non successfull benchmark runs (they are empty)

  // Read relevant data
  final document = lines.where((String line) => line.startsWith("Document Path:")).first;
  final length = lines.where((String line) => line.startsWith("Document Length:")).first;
  final testtime = lines.where((String line) => line.startsWith("Time taken for tests:")).first;
  final completed = lines.where((String line) => line.startsWith("Complete requests:")).first;
  final failed = lines.where((String line) => line.startsWith("Failed requests:")).first;
  final concurrency = lines.where((String line) => line.startsWith("Concurrency Level:")).first;
  final data = lines.where((String line) => line.startsWith("Total transferred:")).first;
  final rps = lines.where((String line) => line.startsWith("Requests per second:")).first;
  final trans = lines.where((String line) => line.startsWith("Transfer rate:")).first;

  // Define some regular expression matchers to read data
  final pingMatcher = new RegExp(r'/ping/\d+');
  final intMatcher = new RegExp(r'\d+');
  final floatMatcher = new RegExp(r'[-+]?(\d*[.])?\d+');

  // Some helpers to apply the above matchers
  final getPing = (s) => pingMatcher.firstMatch(s).group(0);
  final getInt = (s) => intMatcher.firstMatch(s).group(0);
  final getFloat = (s) => floatMatcher.firstMatch(s).group(0);

  // Return a csv line by applying the matchers
  return
    '"${tag.trim()}",'
    '"${getPing(document)}",'
    '"${getInt(length)}",'
    '"${getFloat(testtime)}",'
    '"${getInt(completed)}",'
    '"${getInt(failed)}",'
    '"${getInt(concurrency)}",'
    '"${getInt(data)}",'
    '"${getFloat(rps)}",'
    '"${getFloat(trans)}"';
}

/**
 * Analyzes apachebench log data.
 * Returns a csv file on stdout.
 */
void main(args) {

  // Command line options for the analyze script
  final options = new ArgParser();
  options.addOption('tag', abbr: 't', defaultsTo: '', help: 'used to tag a dataset');

  final params = options.parse(args);
  final tags = params['tag'].split(",").map((s) => s.trim()); // Tags to assign
  final files = params.rest; // Files to process

  // Processes a set of given files.
  // Tags are assigned according to the order specified by the parameter --tag
  // --tag=tag1,tag2,tag2,tag3
  var count = 0;
  final reads = files.map((fname) {
    final file = new File(fname);
    final item = count++;

    final Future<String> read  = file.readAsString().then((log) {
      final tag = tags.elementAt(item % tags.length);
      final csv = log.split("This is ApacheBench,")
                     .map((data) => extractAndTagData(data, tag.trim()))
                     .where((data) => data.isNotEmpty)
                     .join("\n");
      return csv;
    });

    return read;
  });

  Future.wait(reads).then((csvs) {
    final head = [
     "Tag",
     "Document Path",
     "Document Length",
     "Time taken for tests",
     "Complete requests",
     "Failed requests",
     "Concurrency Level",
     "Total transferred",
     "Requests per second (mean)",
     "Transfer rate",
    ].join(",");

    print("$head\n${csvs.join("\n")}"); // Generates the csv string
  });
}
