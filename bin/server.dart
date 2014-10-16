import 'package:args/args.dart';
import 'ping.dart';
import 'pong.dart';

/**
 * Entry point to start ping or pong server via docker
 */
void main(args) {
  
  // Command line options for the ping server
  final options = new ArgParser();
  options.addOption('url', abbr: 'u', defaultsTo: 'http://localhost:4040', help: 'used to specify the pong url');
  options.addOption('port', abbr: 'p', defaultsTo: '8080', help: 'port number');
  options.addFlag('asPong', defaultsTo: true, negatable: false, help: 'used to start server as pong server');
  options.addFlag('asPing', defaultsTo: false, negatable: false, help: 'used to start server as ping server');
  final flags = options.parse(args);
  
  final url  = options.parse(args)['url'];             // get the url of pong server
  final port = int.parse(options.parse(args)['port']); // get the port number of ping server
  
  if (flags['asPing']) startPingServer(url, port);
  if (flags['asPong'])  startPongServer(port);
}