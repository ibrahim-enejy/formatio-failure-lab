# Scenario 07: Python Asyncio CPU Starvation (Synchronous Blocking in ASGI)

> **Failure Classification:** Event Loop Starvation / GIL Saturation  
> **Affected Framework:** Python (FastAPI / Starlette / Sanic / Tornado)  
> **Difficulty:** Intermediate  

---

## 1. Failure Anatomy

In modern Python ASGI applications (FastAPI/Uvicorn), route handlers defined with `async def` run on a single main event loop thread. 

When a developer inadvertently introduces CPU-heavy synchronous operations (e.g. `json.loads` on multi-megabyte payloads, heavy regex evaluation, image transforms, or non-async database drivers) inside an `async def` function, the entire ASGI event loop freezes for the duration of that computation:
```python
@router.post("/items")
async def process_items():
    # BLOCKING: This synchronous work freezes the single event loop!
    for _ in range(10_000_000):
        math.sqrt(12345)
```

During this stall:
- All incoming HTTP requests to other endpoints wait in the socket buffer.
- Orchestrator liveness probes (`/healthz`) fail.
- Uvicorn workers fail to respond, appearing completely deadlocked.

---

## 2. Reproduction Steps

### Option A: Using the CLI Trigger Script
```bash
./scenarios/07-asyncio-cpu-starvation/trigger.sh http://localhost:8000 6000
```

### Option B: Direct cURL
```bash
# Block event loop for 6 seconds
curl -i -X POST "https://your-python-app.formatio.cloud/api/lab/scenarios/07-asyncio-cpu-starvation?ms=6000"
```

In a separate terminal, execute a health check to observe the latency spike:
```bash
curl -i --max-time 3 https://your-python-app.formatio.cloud/api/lab/status
```

---

## 3. What Happens on Traditional Infrastructure vs. Formatio

| Traditional APM Setup | Formatio Autonomous SRE |
| :--- | :--- |
| Uvicorn worker heartbeat times out; Gunicorn/Uvicorn master kills the worker with `SIGKILL` without stack trace context. | **Formatio Event Loop Delay metrics correlate latency spike** directly to the CPU-intensive sync block. |
| Engineer converts entire framework to multi-process or adds expensive EC2 instances. | **Formatio AI SRE opens a PR** wrapping the compute in `asyncio.to_thread` or switching from `async def` to regular `def` (which FastAPI executes in an external thread pool automatically). |
