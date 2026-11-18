# Scenario 06: Unbounded Goroutine Starvation / Channel Leak

> **Failure Classification:** Concurrency Leak / Goroutine Accumulation  
> **Affected Framework:** Go (Gin / Chi / net/http)  
> **Difficulty:** Advanced  

---

## 1. Failure Anatomy

In Go microservices, goroutines are lightweight (~2KB initial stack), encouraging developers to launch background goroutines without strict lifecycle controls.

A common bug occurs when a goroutine waits to read or write to an unbuffered channel whose receiver or sender has already returned:
```go
go func() {
    ch := make(chan struct{})
    <-ch // Leaked: will NEVER receive a value or terminate
}()
```

As traffic scales:
1. Every incoming HTTP request leaks one or more goroutines.
2. The runtime goroutine count swells from tens to tens of thousands (`NumGoroutine() > 100,000`).
3. Each goroutine retains its stack and any variables in scope. The Go garbage collector spends increasing CPU time scanning stacks, until memory pressure triggers the cgroup OOM killer.

---

## 2. Reproduction Steps

### Option A: Using the CLI Trigger Script
```bash
./scenarios/06-unbounded-goroutine-leak/trigger.sh http://localhost:8080 50000
```

### Option B: Direct cURL
```bash
curl -i -X POST "https://your-go-app.formatio.cloud/api/lab/scenarios/06-goroutine-leak?count=50000"
```

Verify via the telemetry endpoint:
```bash
curl -sS https://your-go-app.formatio.cloud/api/lab/status | jq '.runtime.num_goroutines'
```

---

## 3. What Happens on Traditional Infrastructure vs. Formatio

| Traditional APM Setup | Formatio Autonomous SRE |
| :--- | :--- |
| Standard CPU/RAM graphs slowly climb. SREs suspect a memory leak in a C binding or heap fragmentation. | **Formatio runtime agents profile the Go runtime directly**, tracking `runtime.NumGoroutine()` and goroutine stack creation sites. |
| Pprof dumps must be captured manually while the container is in a degraded state before it restarts. | **Formatio AI SRE pinpoints the channel receive lockup** and opens a PR with a `context.WithTimeout` cancellation pattern. |
