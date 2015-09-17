package main 

import (
	"fmt"
	"flag"
	"pingpong/pong"
	"pingpong/ping"
	"os"
)

func main() {
	aspong := flag.Bool("asPong", false, "Starts Pong service")
	asping := flag.Bool("asPing", false, "Starts Ping service")
	port := flag.Int("port", 8080, "Sets the port")
	ponghost := flag.String("pongHost", "localhost", "Host (valid DNS name or IP) of the pong service")
	pongport := flag.Int("pongPort", 8080, "Port of the pong service")
	flag.Parse()
	
	if (*aspong && *asping) {
		fmt.Println("You can only start ping or pong service, not both with the same command.")
		flag.PrintDefaults()
		os.Exit(1)
	}
	
	if (*aspong) { 
		pong.Start(*port) 
		os.Exit(0)
	}
	
	if (*asping) { 
		ping.Start(*port, *ponghost, *pongport) 
		os.Exit(0)
	}
	
	flag.PrintDefaults()
}

