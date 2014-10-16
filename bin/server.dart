import 'package:args/args.dart';
import 'ping.dart';
import 'pong.dart';

/**
 * The entry point for the docker container
 */
void main(args) {
  
  // Command line options for the docker handling
  final options = new ArgParser();
  options.addFlag('asPong', defaultsTo: true, negatable: false, help: 'used to start server as pong server');
  options.addFlag('asPing', defaultsTo: false, negatable: false, help: 'used to start server as ping server');
  final flags = options.parse(args);
  
  if (flags['asPing']) startPingServer(args);
  if (flags['asPong'])  startPongServer();
}