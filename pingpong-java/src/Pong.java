import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

/**
 * Pong Service of the Ping Pong System.
 * Implemented in Java 8 with Streams.
 * @author Nane Kratzke
 * 
 */
public class Pong {

	private static void registerPongHandlerWith(HttpServer server) {
		server.createContext("/pong", (HttpExchange httpExchange) -> {
			 
			final String[] request = httpExchange.getRequestURI().getPath().split("/");			
			final int length = Integer.parseInt(request[2]);
			
			StringBuffer buffer = new StringBuffer();
			buffer.append("p");
			final String ooo = Stream.generate(() -> "o")
					                 .limit(length < 4 ? 1 : length - 3)
					                 .collect(Collectors.joining(""));
			buffer.append(ooo);
			buffer.append("ng");
			final byte[] out = buffer.toString()
			                         .getBytes("UTF-8");
			
            httpExchange.sendResponseHeaders(200, out.length);
            OutputStream os = httpExchange.getResponseBody();
            os.write(out);
            os.close();
        });		
	}
	
	/**
	 * Starts the Pong Service on a specified port.
	 * @param args Port
	 * 
	 */
	public static void main(String[] args) {
		try {
			if (args.length == 0) {
				System.out.println("Sorry, you have to specify a port as first command line parameter.");
				System.exit(1);
			}
			
			int port = Integer.parseInt(args[0]);
			HttpServer httpServer = HttpServer.create(new InetSocketAddress(port), 0);
	        httpServer.setExecutor(Executors.newCachedThreadPool());

			registerPongHandlerWith(httpServer);
			
			httpServer.start(); 
		    System.out.println("Pong Service Started ... listening on port " + port);
			
		} catch (Exception ex) {
			System.out.println("We got the following exception" + ex);
			System.out.println("while starting the Pong Service.");
			System.out.println("Aborting program execution.");
			System.exit(1);
		}
	}
}
