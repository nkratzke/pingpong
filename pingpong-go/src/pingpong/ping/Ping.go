package ping 

import (
    "net/http"
    "io/ioutil"
    "fmt"
    "github.com/gorilla/mux"
    "time"
)

const RETRIES = 100
const JSONANSWER = "{\"length\": %v, \"code\": %v, \"retries\": %v, \"duration\": %v}"

var pongUrl string

func get(url string) (content string, code int, err error) {
	res, err     := http.Get(url)
	if (err != nil) { return "", http.StatusServiceUnavailable, err }
	
	message, err := ioutil.ReadAll(res.Body)	
	if (err != nil) { return "", http.StatusServiceUnavailable, err }
	
	return string(message), res.StatusCode, err
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	
	for i := 1; i <= RETRIES; i++ {
		message, _, err := get(pongUrl + "/pong/" + params["length"])
		
		if err == nil {
			fmt.Fprintf(w, message)
			return
		}		
	}

	w.WriteHeader(http.StatusServiceUnavailable);
	w.Write([]byte("Service unavailable"))
}

func mpingHandler(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)

	start := time.Now().UnixNano()
	for retries := 0; retries < RETRIES; retries++ {
		message, code, err   := get(pongUrl + "/pong/" + params["length"])
		if err == nil {
			end := time.Now().UnixNano()
			duration := float64(end - start) / 1000.0 / 1000.0
			json := fmt.Sprintf(JSONANSWER, len(message), code, retries, duration)
			w.Write([]byte(json))
			return
		}
	}

	end := time.Now().UnixNano()
	duration := float64(end - start) / 1000.0 / 1000.0
	json := fmt.Sprintf(JSONANSWER, 0, http.StatusServiceUnavailable, RETRIES, duration)
	w.Write([]byte(json))
}

func Start(port int, ponghost string, pongport int) {
    myport := fmt.Sprintf(":%v", port)
    
    pongUrl = fmt.Sprintf("http://%s:%v",  ponghost, pongport)
    
    r := mux.NewRouter()
    r.HandleFunc("/ping/{length:[0-9]+}", pingHandler)
    r.HandleFunc("/mping/{length:[0-9]+}", mpingHandler)
        
	fmt.Printf("Ping service is up and listening on port %v\n", port)
    fmt.Printf("Pong service assumed to be reachable at %s\n", pongUrl)
    http.ListenAndServe(myport, r)   
}