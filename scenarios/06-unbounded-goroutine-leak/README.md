# Scenario 06: Unbounded goroutine starvation and channel leak

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Failure classification:** Concurrency leak / goroutine accumulation  
> **Affected framework:** Go (`apps/go-gin`)  
> **Difficulty:** Advanced

---

## 1. Failure anatomy

Launching goroutines that block forever on unbuffered channels with no sender or context cancellation leaks stacks on every request until GC scans stall CPU and container RAM triggers OOM kill.

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
./scenarios/06-unbounded-goroutine-leak/trigger.sh http://localhost:8080 50000
```

### Option B: Direct curl
```bash
curl -i -X POST "https://your-go-app.formatio.cloud/api/lab/scenarios/06-goroutine-leak?count=50000"
curl -sS https://your-go-app.formatio.cloud/api/lab/status | jq '.runtime.num_goroutines'
```

---

## 3. Traditional APM vs. Formatio

| Traditional APM setup | Formatio |
| :--- | :--- |
| CPU/RAM graphs climb slowly without pinpointing the leaking Go handler commit. | Go compile-time Railpack OpenTelemetry traces link the request surge directly to the deployment commit and memory/CPU climb. |
| Pprof captures must happen manually before container restart. | Built-in AI error advisor isolates the unclosed channel block and autonomous AI SRE opens a fix PR using `context.WithTimeout` (patch in [`solution.patch`](./solution.patch)). |
