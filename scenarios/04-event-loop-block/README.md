# Scenario 04: CPU starvation and event loop blocking

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Failure classification:** CPU starvation / single-thread bottleneck  
> **Affected framework:** Node.js  
> **Difficulty:** Intermediate

---

## 1. Failure anatomy

Heavy synchronous tasks (catastrophic regex evaluation, blocking loops, large sync transforms) stall Node.js's single event loop thread so concurrent requests and `/healthz` readiness checks freeze.

```text
[Main thread] ---[Synchronous CPU loop (5s)]--->
                        ▲
                        │ All I/O, timers, and /healthz probes blocked
```

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
./scenarios/04-event-loop-block/trigger.sh http://localhost:3000
```

### Option B: Direct curl
```bash
curl -i -X POST "https://your-app.formatio.cloud/api/lab/scenarios/04-event-loop-block?ms=6000"
```

Run a concurrent healthcheck in another terminal to observe the stall:
```bash
curl -i --max-time 2 https://your-app.formatio.cloud/healthz
```

---

## 3. Traditional APM vs. Formatio

| Traditional APM setup | Formatio |
| :--- | :--- |
| Container restarts after failed healthchecks without tracing the blocking handler commit. | Trace waterfalls and latency metrics correlate the freeze straight to `/api/lab/scenarios/04-event-loop-block` and its release commit. |
| Engineer spends hours guessing between DB locks and memory leaks. | Built-in AI error advisor (works out of the box) and autonomous AI SRE open a fix PR moving heavy compute off the event loop (patch in [`solution.patch`](./solution.patch)). |
