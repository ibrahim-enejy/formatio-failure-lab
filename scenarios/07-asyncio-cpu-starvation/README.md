# Scenario 07: Python asyncio CPU starvation (sync blocking in ASGI)

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Failure classification:** Event loop starvation / GIL saturation  
> **Affected framework:** Python (`apps/python-fastapi`)  
> **Difficulty:** Intermediate

---

## 1. Failure anatomy

In FastAPI/Uvicorn, `async def` handlers run on a single asyncio event loop. Running synchronous CPU-heavy work directly inside `async def` stalls every concurrent route and healthcheck until timeouts trip.

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
./scenarios/07-asyncio-cpu-starvation/trigger.sh http://localhost:8000 6000
```

### Option B: Direct curl
```bash
curl -i -X POST "https://your-python-app.formatio.cloud/api/lab/scenarios/07-asyncio-cpu-starvation?ms=6000"
```

Verify concurrent stall in another terminal:
```bash
curl -i --max-time 3 https://your-python-app.formatio.cloud/healthz
```

---

## 3. Traditional APM vs. Formatio

| Traditional APM setup | Formatio |
| :--- | :--- |
| Uvicorn worker heartbeats time out and master kills the process with `SIGKILL`. | Railpack automatic `formatio-otel` startup preload captures the trace duration anomaly against the deployed SHA. |
| Engineers add extra compute instances unnecessarily. | Built-in AI error advisor (works out of the box) and autonomous AI SRE open a fix PR moving CPU work to `asyncio.to_thread` or standard `def` (patch in [`solution.patch`](./solution.patch)). |
