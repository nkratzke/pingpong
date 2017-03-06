package pong

import (
	"bytes"
	"fmt"
	"net/http"
	"strconv"
    
    "github.com/gorilla/mux"
)

func pongHandler(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	i, _ := strconv.Atoi(params["length"])
	i -= 4
	var result bytes.Buffer
	result.WriteString("po")
	for ; i > 0; i-- {
		result.WriteString("o")
	}
	result.WriteString("ng")
	w.Write(result.Bytes())
}

func Start(port int) {
	r := mux.NewRouter()
	r.HandleFunc("/pong/{length:[0-9]+}", pongHandler)
	sport := fmt.Sprintf(":%v", port)

	fmt.Printf("Pong service is up and listening on port %v", port)
	http.ListenAndServe(sport, r)
}
