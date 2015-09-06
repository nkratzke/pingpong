import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.OutputStream;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * Ping Service of the Ping Pong System.
 * Implemented in Java 8 with Streams.
 * @author Nane Kratzke
 */
public class Ping {

	/**
	 * Amount of retries to connect with the Pong Service.
	 */
	public final static int RETRIES = 100;

    /**
     * Sends a HTTP get request to a pong service.
     * @param host Host (valid IP or valid DNS name) of the pong service.
     * @param port Valid port number of the pong service.
     * @param length Length in bytes of the to be retrieved message (must be positive).
     * @return A map with the following structure:
     *         {
     *            'content' : String,
     *            'retries' : Integer
     *         }
     */
	private static Map<String, String> get(String host, int port, int length) {
		int retries = 0;
		final Map<String, String> answer = new HashMap<String, String>();
		while (retries < RETRIES) {
			try {
				URL url = new URL("http://" + host + ":" + port + "/pong/" + length);
				BufferedReader in  = new BufferedReader(new InputStreamReader(url.openStream()));
				
				StringBuffer buffer = new StringBuffer();
				String line = "";
				while ((line = in.readLine()) != null) buffer.append(line);
				in.close();
				
				answer.put("content", buffer.toString());
				answer.put("retries", retries + "");
				return answer;				
			} catch (Exception ex) {
				retries++;
			}
		}
		
		answer.put("content", "no connection possible");
		answer.put("retries", retries + "");
		return answer;
	}

	/**
	 * Implements the ping handling for the Ping Service
	 * @param server Server object the handling should registered with
	 * @param ip Ip (or DNS name) address of the pong service
	 * @param port Port number of the pong service
	 * @throws IOException on network connection problems or wrong requests (number formats)
	 */
	private static void registerPingHandlerWith(HttpServer server, String ip, int port) throws IOException {
		server.createContext("/ping", (HttpExchange httpExchange) -> {

			System.out.println("I got the following request " + httpExchange.getRequestURI());
			
			final String[] request = httpExchange.getRequestURI().getPath().split("/");			
			final int length = Integer.parseInt(request[2]);
			
			final Map<String, String> answer = get(ip, port, length);
			final byte[] content = answer.get("content").getBytes("UTF-8");
			
			int responseCode = answer.get("content").length() == length ? 200 : 504;
			
            httpExchange.sendResponseHeaders(responseCode, content.length);
            OutputStream os = httpExchange.getResponseBody();
            os.write(content);
            os.close();
        });
	}

	/**
	 * Implements the meta ping handling for the Ping Service.
	 * Returning detailed benchmark data
	 * @param server Server object the handling should registered with
	 * @param ip Ip (or DNS name) address of the pong service
	 * @param port Port number of the pong service
	 * @throws IOException on network connection problems or wrong requests (number formats)
	 */
	private static void registerMPingHandlerWith(HttpServer server, String ip, int port) {
		server.createContext("/mping", (HttpExchange httpExchange) -> {
			final String[] request = httpExchange.getRequestURI().getPath().split("/");			
			final int length = Integer.parseInt(request[2]);
			
			final Map<String, String> answer = get(ip, port, length);
			
			long start = System.nanoTime();
			final byte[] content = answer.get("content").getBytes("UTF-8");
			long end = System.nanoTime();
			
			int responseCode = content.length == length ? 200 : 503;
			double duration = (end - start) / 1000000.0; // milliseconds
			String retries = answer.get("retries");
			
			final byte[] json = ( 
					"{\n" +
					"  'length': " + content.length + ",\n" +
					"  'code': " + responseCode + ",\n" + 
					"  'duration': " + duration + ",\n" +
					"  'retries': " + retries + "\n" +
					"}\n").getBytes("UTF-8");
			
            httpExchange.sendResponseHeaders(responseCode, json.length);
            OutputStream os = httpExchange.getResponseBody();
            os.write(json);
            os.close();
        });
	}
	
	/**
	 * Starts the Ping Service on a specified port
	 * and stores connection parameters (host and port) of
	 * the Pong service.
	 * 
	 * All parameters are passed via command line
	 * parameters args
	 * 
	 * @param args Own port, IP of the pong service, Port of the pong service
	 */
	public static void main(String[] args) {	
		
		if (args.length < 3) {
			System.out.println("Sorry, you have to specify"); 
			System.out.println("- a port for the ping service as first command line parameter");
			System.out.println("- a host/ip for the pong service as second command line parameter");
			System.out.println("- a port for the pong service as third command line parameter");
			System.out.println("");
			System.out.println("It seems, you started ping like that");
			System.out.println("java Ping " + Arrays.stream(args).collect(Collectors.joining(", ")));
			System.out.println("So please use: java Ping <pingport> <ponghost> <pongport>");
			System.exit(1);
		}
		
		try {
			int pingPort = Integer.parseInt(args[0]);
			String pongHost = args[1];
			int pongPort = Integer.parseInt(args[2]);
			
			HttpServer httpServer = HttpServer.create(new InetSocketAddress(pingPort), 0);
	        httpServer.setExecutor(Executors.newCachedThreadPool());

			registerPingHandlerWith(httpServer, pongHost, pongPort);
			registerMPingHandlerWith(httpServer, pongHost, pongPort);
			
			httpServer.start(); 
		    System.out.println("Ping Service Started ...");
			
		} catch (Exception ex) {
			System.out.println("We got the following exception" + ex);
			System.out.println("while starting the Ping Service.");
			System.out.println("Aborting program execution.");
		}
	}
}
