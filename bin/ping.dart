library ping;

import 'package:start/start.dart';
import 'package:http/http.dart' as http;
import 'package:args/args.dart';

/**
 * Starts the ping server.
 */
void startPingServer(url, port) {

  int errorCounter = 0;

  start(host: "0.0.0.0", port: port).then((app) {
    app.get("/ping/:length").listen((req) async {
      int len = int.parse(req.param('length'), onError: (len) {
        print("A message of undefined length has been requested ('$len'). Switching to standard length 4 ('pong')");
        return 4;
      });

      var tries = 0;

      while (tries < 10) {
        try {
          var response = await http.get("$url/pong/$len");
          req.response.status(200);
          req.response.send(response.body);
          req.response.close();
        } catch (e) {
          print(e);
          print("But we will retry.");
          tries++;
        }
      }

      if (tries >= 10) {
        req.response.status(503);
        req.response.send("Pong server is not answering");
        req.response.close();
        print("$errorCounter non resolveable problem");
        errorCounter++;
      }

      /*.then((response) {
        req.response.status(200);
        req.response.send(response.body);
      }).catchError((err) {
        print(err);
        req.response.status(503);
        req.response.send("Pong server is not answering");
      });*/
    });

    print("Ping-Server is up and running, Listening on port $port");
    print("Pong-Server assumed to be reachable at $url");

  });
}

/**
 * Entrypoint to start the ping relay server without docker.
 */
void main(args) {
  // Command line options for the ping server
  final options = new ArgParser();
  options.addOption('url', abbr: 'u', defaultsTo: 'http://localhost:4040', help: 'used to specify the pong url');
  options.addOption('port', abbr: 'p', defaultsTo: '8080', help: 'port number');

  final url  = options.parse(args)['url'];             // get the url of pong server
  final port = int.parse(options.parse(args)['port']); // get the port number of ping server

  startPingServer(url, port);
}
