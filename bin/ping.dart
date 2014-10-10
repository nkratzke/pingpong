import 'package:start/start.dart';
import 'package:http/http.dart' as http;

final PORT = 8080;                            // port number of the ping server
final pongUrl = "http://localhost:4040/pong"; // url of the pong server

/**
 * Entrypoint to start the ping relay server.
 */
void main() {

  start(host: "0.0.0.0", port: PORT).then((app) {
    app.get("/ping/:length").listen((req) {
      int len = int.parse(req.param('length'));

      http.get("$pongUrl/$len").then((response) {
        req.response.send(response.body);
      }).catchError((err) {
        print(err);
        req.response.send("Pong server is not answering");
      });
    });

    print("Ping-Server is up and running, Listening on port $PORT");

  });
}
