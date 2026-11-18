# Scenario 04: CPU Starvation & Event Loop Blocking

> **Failure Classification:** CPU Starvation / Single-Thread Bottleneck  
> **Affected Framework:** Node.js (V8 Event Loop Block) / Single-Thread Runtimes  
> **Difficulty:** Intermediate  

---

## 1. Failure Anatomy

Node.js runs user JavaScript code on a single thread. When compute-heavy tasks (regular expression Denial of Service, heavy synchronous JSON parsing, cryptographic hashing, or large array transforms) run synchronously on the main thread, the entire event loop freezes.

While the event loop is blocked:
- No incoming HTTP connections are accepted.
- Health-check probes (`/healthz` or `/api/lab/status`) fail and trigger Kubernetes / ECS container restarts.
- Active websocket connections drop.
- All concurrent users experience infinite loading or timeouts.

```text
[Main Thread] ───[Synchronous CPU-intensive loop (5s)]───>
                        ▲
                        │ All I/O, timers & incoming HTTP requests blocked
[Health Check] ──X (Timed out) ──> Orchestrator kills container
```

---

## 2. Reproduction Steps

### Option A: Using the CLI Trigger Script
```bash
./scenarios/04-event-loop-block/trigger.sh http://localhost:3000
```

### Option B: Direct cURL
```bash
# Block event loop for 6000ms (6 seconds)
curl -i -X POST "https://your-app.formatio.cloud/api/lab/scenarios/04-event-loop-block?ms=6000"
```

To see the blast radius, run a health-check in another terminal simultaneously:
```bash
curl -i --max-time 2 https://your-app.formatio.cloud/api/lab/status
```
Notice that the health-check will not respond until the 6-second block completes.

---

## 3. What Happens on Traditional Infrastructure vs. Formatio

| Traditional APM Setup | Formatio Autonomous SRE |
| :--- | :--- |
| Container metrics show CPU spike to 100% of single core. Health check fails after 3 retries; container is restarted without identifying the root cause. | **Formatio Event Loop Delay metrics (ELDO)** spike instantly, correlating the hang directly to the route handler. |
| Engineer assumes memory leak or database deadlock, spending hours profiling the wrong subsystem. | **Formatio AI SRE diagnoses the CPU hotspot** and opens a PR offloading the computation to a worker thread or chunking via `setImmediate`. |
