# Formatio Failure Lab: Go / Gin Microservice

> High-throughput Go REST microservice designed for diagnosing concurrency deadlocks, memory leaks, channel blocking, and unbounded goroutine starvation.

---

## Quickstart

### Local Execution
```bash
go run main.go
```

### Docker
```bash
docker build -t formatio-failure-lab-go .
docker run -p 8080:8080 formatio-failure-lab-go
```

### Deploy to Formatio
1. Fork or push this repository to GitHub.
2. In the [Formatio Dashboard](https://formatio.cloud/dashboard), select **New application** → choose this repo.
3. Set **Directory** to `apps/go-gin`.
4. Click **Deploy**. Formatio detects Go, compiles the binary, and injects runtime telemetry.

---

## Live endpoints

- `GET /healthz`: Readiness check (returns HTTP `503` when `SIMULATE_BAD_HEALTHCHECK=true`).
- `GET /api/lab/status`: Live Go runtime telemetry (`Alloc`, `Sys`, `NumGoroutine`, GC statistics).
- `POST /api/lab/scenarios/01-oom`: Unbounded slice allocations forcing container OOM killer.
- `POST /api/lab/scenarios/02-hang`: 15-second upstream dependency hang.
- `POST /api/lab/scenarios/06-goroutine-leak?count=50000`: Leaks 50,000 un-reclaimed goroutines blocked on an empty channel.
