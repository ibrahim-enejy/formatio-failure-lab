// Lean Go microservice for Formatio Failure Lab combining stock OpenTelemetry SDK tracing
// (configured purely from Formatio's OTEL_* env vars), multi-service distributed cascades,
// Automatic Fix PR fixtures, and Go runtime chaos scenarios (01, 02, 06, 08, 12, 17, 18).
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"math/rand/v2"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"strconv"
	"sync"
	"syscall"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/trace"
)

var (
	tracer          = otel.Tracer("failure-lab-go")
	startTime       = time.Now()
	errUserNotFound = errors.New("user not found")
	errRatesDB      = errors.New("dial tcp 10.0.4.12:5432: connect: connection refused")
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	shutdown, err := setupTracing(ctx)
	if err != nil {
		log.Fatalf("tracing setup failed: %v", err)
	}
	defer func() {
		shutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = shutdown(shutCtx)
	}()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", index)
	mux.HandleFunc("GET /healthz", healthz)
	mux.HandleFunc("GET /api/lab/status", labStatus)
	mux.HandleFunc("GET /ai-sre/shipping-total", shippingTotal)

	// Stock OTel grouping & latency routes
	mux.HandleFunc("GET /ok", okHandler)
	mux.HandleFunc("GET /slow", slowHandler)
	mux.HandleFunc("GET /exception", exceptionHandler)
	mux.HandleFunc("GET /not-found/{id}", notFoundHandler)
	mux.HandleFunc("GET /status-500", status500Handler)
	mux.HandleFunc("GET /crash", crashHandler)
	mux.HandleFunc("GET /downstream", downstreamHandler)

	// Distributed mesh routes (Scenarios 17 & 18)
	mux.HandleFunc("POST /orders", createOrder)
	mux.HandleFunc("GET /api/dashboard", dashboardHandler)
	mux.HandleFunc("GET /internal/rates", ratesHandler)

	// Runtime chaos routes (Scenarios 01, 02, 06)
	mux.HandleFunc("/api/lab/scenarios/01-oom", oomHandler)
	mux.HandleFunc("/api/lab/scenarios/02-hang", hangHandler)
	mux.HandleFunc("/api/lab/scenarios/06-goroutine-leak", goroutineLeakHandler)

	// recoverPanics runs inside otelhttp so panics record stack traces onto the active span.
	handler := otelhttp.NewHandler(recoverPanics(mux), "failure-lab-go",
		otelhttp.WithSpanNameFormatter(func(_ string, r *http.Request) string {
			if r.Pattern != "" {
				return r.Pattern
			}
			return r.Method + " " + r.URL.Path
		}),
	)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	srv := &http.Server{Addr: ":" + port, Handler: handler}
	go func() {
		<-ctx.Done()
		_ = srv.Shutdown(context.Background())
	}()

	log.Printf("failure-lab-go listening on :%s, exporting OTLP to %q", port, os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT"))
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}

func setupTracing(ctx context.Context) (func(context.Context) error, error) {
	exporter, err := otlptracehttp.New(ctx)
	if err != nil {
		return nil, err
	}
	res, err := resource.New(ctx, resource.WithFromEnv(), resource.WithTelemetrySDK())
	if err != nil {
		return nil, err
	}
	provider := sdktrace.NewTracerProvider(sdktrace.WithBatcher(exporter), sdktrace.WithResource(res))
	otel.SetTracerProvider(provider)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))
	return provider.Shutdown, nil
}

func index(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lab":        "Formatio Open-Source Failure Lab",
		"framework":  "Go / net/http + otelhttp",
		"status_url": "/api/lab/status",
		"routes": []string{
			"/healthz",
			"/ok",
			"/slow?ms=1500",
			"/exception",
			"/not-found/{id}",
			"/status-500",
			"/crash",
			"/downstream?path=/exception",
			"/ai-sre/shipping-total?pickup=1",
			"POST /orders",
			"/api/dashboard",
			"/internal/rates",
			"/api/lab/scenarios/01-oom",
			"/api/lab/scenarios/02-hang",
			"/api/lab/scenarios/06-goroutine-leak?count=50000",
		},
	})
}

func healthz(w http.ResponseWriter, _ *http.Request) {
	if os.Getenv("SIMULATE_BAD_HEALTHCHECK") == "true" {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{
			"status": "unhealthy",
			"reason": "SIMULATE_BAD_HEALTHCHECK=true",
		})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{
		"status":  "ok",
		"service": "go-gin",
	})
}

func bToMb(b uint64) uint64 {
	return b / 1024 / 1024
}

func labStatus(w http.ResponseWriter, _ *http.Request) {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	writeJSON(w, http.StatusOK, map[string]any{
		"status": "online",
		"app":    "Formatio Failure Lab — Go/net/http (OTel)",
		"runtime": map[string]any{
			"go_version":     runtime.Version(),
			"os":             runtime.GOOS,
			"arch":           runtime.GOARCH,
			"num_cpu":        runtime.NumCPU(),
			"num_goroutines": runtime.NumGoroutine(),
			"uptime_seconds": int(time.Since(startTime).Seconds()),
		},
		"memory": map[string]any{
			"alloc_mb":       bToMb(m.Alloc),
			"total_alloc_mb": bToMb(m.TotalAlloc),
			"sys_mb":         bToMb(m.Sys),
			"num_gc":         m.NumGC,
		},
		"scenarios": map[string]string{
			"01-heap-oom":       "POST /api/lab/scenarios/01-oom",
			"02-hang":           "POST /api/lab/scenarios/02-hang",
			"06-goroutine-leak": "POST /api/lab/scenarios/06-goroutine-leak?count=50000",
			"12-shipping-fix":   "GET /ai-sre/shipping-total?pickup=1",
		},
	})
}

func okHandler(w http.ResponseWriter, r *http.Request) {
	ctx, span := tracer.Start(r.Context(), "load dashboard")
	defer span.End()
	for _, step := range []string{"query users", "query orders", "render"} {
		_, child := tracer.Start(ctx, step, trace.WithAttributes(attribute.String("step", step)))
		time.Sleep(time.Duration(5+rand.IntN(20)) * time.Millisecond)
		child.End()
	}
	fmt.Fprintln(w, "ok")
}

func slowHandler(w http.ResponseWriter, r *http.Request) {
	ms, err := strconv.Atoi(r.URL.Query().Get("ms"))
	if err != nil || ms <= 0 {
		ms = 1500
	}
	_, span := tracer.Start(r.Context(), "slow work", trace.WithAttributes(attribute.Int("sleep.ms", ms)))
	time.Sleep(time.Duration(ms) * time.Millisecond)
	span.End()
	fmt.Fprintf(w, "slept %dms\n", ms)
}

func exceptionHandler(w http.ResponseWriter, r *http.Request) {
	err := loadInvoice(r.Context())
	fail(w, r, err, http.StatusInternalServerError)
}

func loadInvoice(ctx context.Context) error {
	_, span := tracer.Start(ctx, "load invoice")
	defer span.End()
	err := fmt.Errorf("invoice total is negative: %w", errors.ErrUnsupported)
	span.RecordError(err, trace.WithStackTrace(true))
	span.SetStatus(codes.Error, err.Error())
	return err
}

func notFoundHandler(w http.ResponseWriter, r *http.Request) {
	err := fmt.Errorf("user %s: %w", r.PathValue("id"), errUserNotFound)
	fail(w, r, err, http.StatusNotFound)
}

func status500Handler(w http.ResponseWriter, r *http.Request) {
	trace.SpanFromContext(r.Context()).SetStatus(codes.Error, "upstream quota exhausted")
	http.Error(w, "upstream quota exhausted", http.StatusInternalServerError)
}

func crashHandler(_ http.ResponseWriter, _ *http.Request) {
	var cache map[string][]int
	cache["user"][3] = 1
}

func downstreamHandler(w http.ResponseWriter, r *http.Request) {
	base := os.Getenv("DOWNSTREAM_URL")
	if base == "" {
		base = "http://node-express:3000"
	}
	targetPath := r.URL.Query().Get("path")
	if targetPath == "" {
		targetPath = "/exception"
	}

	client := http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport), Timeout: 10 * time.Second}
	req, _ := http.NewRequestWithContext(r.Context(), http.MethodGet, base+targetPath, nil)
	resp, err := client.Do(req)
	if err != nil {
		fail(w, r, err, http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 500 {
		trace.SpanFromContext(r.Context()).SetStatus(codes.Error, fmt.Sprintf("downstream answered %d", resp.StatusCode))
		w.WriteHeader(http.StatusBadGateway)
	}
	fmt.Fprintf(w, "downstream %s%s → %d: %s", base, targetPath, resp.StatusCode, body)
}

type order struct {
	Items []struct {
		SKU string `json:"sku"`
		Qty int    `json:"qty"`
	} `json:"items"`
	Total *float64 `json:"total"`
}

func createOrder(w http.ResponseWriter, r *http.Request) {
	var o order
	if err := json.NewDecoder(r.Body).Decode(&o); err != nil {
		fail(w, r, err, http.StatusBadRequest)
		return
	}
	base := os.Getenv("PAYMENTS_URL")
	if base == "" {
		base = os.Getenv("PYTHON_URL")
	}
	if base == "" {
		base = "http://python-fastapi:8000"
	}

	ctx := r.Context()
	_, reserve := tracer.Start(ctx, "reserve inventory", trace.WithAttributes(attribute.Int("order.items", len(o.Items))))
	time.Sleep(time.Duration(10+rand.IntN(20)) * time.Millisecond)
	reserve.End()

	body, _ := json.Marshal(map[string]any{"amount": o.Total, "currency": "USD"})
	client := http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport), Timeout: 10 * time.Second}
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, base+"/charge", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err == nil {
		defer resp.Body.Close()
	}
	if err != nil || resp.StatusCode >= 500 {
		_, release := tracer.Start(ctx, "release inventory")
		time.Sleep(time.Duration(5+rand.IntN(10)) * time.Millisecond)
		release.End()

		reason := "payment service unreachable"
		if err == nil {
			reason = fmt.Sprintf("payment service answered %d", resp.StatusCode)
		}
		trace.SpanFromContext(ctx).SetStatus(codes.Error, reason)
		http.Error(w, reason, http.StatusBadGateway)
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"order":   fmt.Sprintf("ord_%d", rand.IntN(1_000_000)),
		"charged": o.Total,
	})
}

func ratesHandler(w http.ResponseWriter, r *http.Request) {
	_, span := tracer.Start(r.Context(), "query rates-db", trace.WithAttributes(
		attribute.String("db.system", "postgresql"),
		attribute.String("db.operation", "SELECT"),
	))
	time.Sleep(time.Duration(20+rand.IntN(20)) * time.Millisecond)
	if r.URL.Query().Get("healthy") == "" {
		err := fmt.Errorf("load exchange rates: %w", errRatesDB)
		span.RecordError(err, trace.WithStackTrace(true))
		span.SetStatus(codes.Error, err.Error())
		span.End()
		trace.SpanFromContext(r.Context()).SetStatus(codes.Error, "rates database unavailable")
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{"error": "rates database unavailable"})
		return
	}
	span.End()
	writeJSON(w, http.StatusOK, map[string]any{"base": "USD", "EUR": 0.92, "GBP": 0.79})
}

func dashboardHandler(w http.ResponseWriter, r *http.Request) {
	base := os.Getenv("PYTHON_URL")
	if base == "" {
		base = os.Getenv("PAYMENTS_URL")
	}
	if base == "" {
		base = "http://python-fastapi:8000"
	}
	suffix := ""
	if r.URL.Query().Get("healthy") != "" {
		suffix = "?healthy=1"
	}

	ctx := r.Context()
	_, profile := tracer.Start(ctx, "load profile")
	time.Sleep(time.Duration(5+rand.IntN(10)) * time.Millisecond)
	profile.End()

	client := http.Client{Transport: otelhttp.NewTransport(http.DefaultTransport), Timeout: 10 * time.Second}
	widgets := map[string]string{"recommendations": "/recommendations", "loyalty": "/loyalty" + suffix}
	results := map[string]json.RawMessage{}
	failures := map[string]int{}
	var mu sync.Mutex
	var wg sync.WaitGroup
	for name, targetPath := range widgets {
		wg.Add(1)
		go func(name, targetPath string) {
			defer wg.Done()
			req, _ := http.NewRequestWithContext(ctx, http.MethodGet, base+targetPath, nil)
			resp, err := client.Do(req)
			mu.Lock()
			defer mu.Unlock()
			if err != nil {
				failures[name] = http.StatusBadGateway
				return
			}
			defer resp.Body.Close()
			rawBody, _ := io.ReadAll(resp.Body)
			if resp.StatusCode >= 400 {
				failures[name] = resp.StatusCode
				return
			}
			results[name] = rawBody
		}(name, targetPath)
	}
	wg.Wait()

	for name, status := range failures {
		trace.SpanFromContext(ctx).SetStatus(codes.Error, fmt.Sprintf("%s widget answered %d", name, status))
		writeJSON(w, http.StatusBadGateway, map[string]any{"error": name + " unavailable"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"profile":         map[string]any{"name": "Ada", "plan": "pro"},
		"recommendations": results["recommendations"],
		"loyalty":         results["loyalty"],
	})
}

func oomHandler(w http.ResponseWriter, _ *http.Request) {
	fmt.Println("[Sabotage] Starting unbounded memory allocation in Go heap...")
	go func() {
		var leak [][]byte
		for {
			chunk := make([]byte, 10*1024*1024)
			for i := range chunk {
				chunk[i] = 1
			}
			leak = append(leak, chunk)
		}
	}()
	writeJSON(w, http.StatusAccepted, map[string]string{
		"status":   "triggered",
		"scenario": "01-heap-oom-crash",
		"message":  "Unbounded 10MB Go slice allocation started.",
	})
}

func hangHandler(w http.ResponseWriter, _ *http.Request) {
	fmt.Println("[Sabotage] Simulating 15-second upstream timeout...")
	time.Sleep(15 * time.Second)
	writeJSON(w, http.StatusOK, map[string]string{
		"status":  "resolved",
		"message": "Upstream slow dependency resolved after 15s.",
	})
}

func goroutineLeakHandler(w http.ResponseWriter, r *http.Request) {
	countStr := r.URL.Query().Get("count")
	if countStr == "" {
		countStr = "50000"
	}
	count, err := strconv.Atoi(countStr)
	if err != nil || count <= 0 {
		count = 50000
	}
	fmt.Printf("[Sabotage] Spawning %d abandoned goroutines waiting on nil channel...\n", count)
	for i := 0; i < count; i++ {
		go func() {
			ch := make(chan struct{})
			<-ch
		}()
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"status":                    "triggered",
		"scenario":                  "06-goroutine-leak",
		"leaked_goroutines_spawned": count,
		"total_active_goroutines":   runtime.NumGoroutine(),
		"message":                   fmt.Sprintf("Spawned %d permanently blocked goroutines on nil channels.", count),
	})
}

func fail(w http.ResponseWriter, r *http.Request, err error, status int) {
	span := trace.SpanFromContext(r.Context())
	span.RecordError(err, trace.WithStackTrace(true))
	span.SetStatus(codes.Error, err.Error())
	http.Error(w, err.Error(), status)
}

func recoverPanics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if v := recover(); v != nil {
				fail(w, r, fmt.Errorf("panic: %v", v), http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
