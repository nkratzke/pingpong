package main 

import (
	"fmt"
	"flag"
	"pong"
	"ping"
	"os"
)

func main() {
	aspong := flag.Bool("asPong", false, "Starts Pong service (defaults to false)")
	asping := flag.Bool("asPing", false, "Starts Ping service (defaults to false)")
	port := flag.Int("port", 8080, "Sets the port (defaults to 8080)")
	ponghost := flag.String("pongHost", "localhost", "Host (valid DNS name or IP) of the pong service (defaults to localhost)")
	pongport := flag.Int("pongPort", 8080, "Port of the pong service (defaults to 8080)")
	flag.Parse()
	
	if (*aspong && *asping) {
		fmt.Println("You can only start ping or pong service, not both with the same command.")
		os.Exit(1)
	}
	
	if (*aspong) { pong.Start(*port) }
	if (*asping) { ping.Start(*port, *ponghost, *pongport) }
}

