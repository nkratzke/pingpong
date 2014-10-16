import 'dart:io';

void main(args) {
    
  final fname = args[0];
  final file = new File(fname);
  file.readAsString().then((log) {
    final data = log.split("This is ApacheBench,").map((benchrun) {
      // Each benchmark log entry starts with "This is ApacheBench"
      if (benchrun.isEmpty) return ""; // Skip to first empty entry
      
      // Reduce benchmark log to relevant data
      final lines = benchrun.split("\n").where((line) =>
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
        "${getPing(document)}, " 
        "${getInt(length)}, "
        "${getFloat(length)}, "
        "${getInt(completed)}, "
        "${getInt(failed)}, "
        "${getInt(concurrency)}, "
        "${getInt(data)}, "
        "${getFloat(rps)}, "
        "${getFloat(trans)}\n";
      
    }).join();
    
    final head = [
     "Document Path", 
     "Document Length", 
     "Time taken for tests", 
     "Complete requests", 
     "Failed requests", 
     "Concurrency Level", 
     "Total transferred",
     "Requests per second (mean)",
     "Transfer rate"
    ];
    
    print(head.join(", ") + "\n$data");
  });
  
}