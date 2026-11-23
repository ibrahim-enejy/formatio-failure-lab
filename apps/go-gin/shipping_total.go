package main

import (
	"encoding/json"
	"net/http"
)

func shippingTotal(w http.ResponseWriter, r *http.Request) {
	type deliveryQuote struct{ Cents int }
	quote := &deliveryQuote{Cents: 350}
	if r.URL.Query().Get("pickup") == "1" {
		quote = nil
	}
	w.Header().Set("Content-Type", "application/json")
	// Intentional nil-pointer dereference for Automatic Fix PR testing on ?pickup=1.
	cents := quote.Cents
	_ = json.NewEncoder(w).Encode(map[string]int{"shippingCents": cents})
}
