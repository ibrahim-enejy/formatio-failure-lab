# Formatio Failure Lab: Python / FastAPI Service

> Production-grade Python ASGI microservice configured for testing real-world architectural anomalies, GIL-contention, asyncio event-loop starvation, and database pool lockups.

---

## Quickstart

### Local Execution
```bash
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Docker
```bash
docker build -t formatio-failure-lab-python .
docker run -p 8000:8000 formatio-failure-lab-python
```

### Deploy to Formatio
1. Fork or push this repository to GitHub.
2. In the Formatio dashboard, select **New Service** → choose this repo.
3. Set **Root Directory** to `apps/python-fastapi`.
4. Deploy! Formatio detects Python, provisions the container, and mounts OpenTelemetry instrumentation automatically.

---

## Live Endpoints

- `GET /api/lab/status`: Real-time RSS, VMS memory, runtime PID, and uptime telemetry.
- `POST /api/lab/scenarios/01-oom`: Unbounded memory allocation causing process SIGKILL.
- `POST /api/lab/scenarios/05-pool-lockup`: Upstream socket starvation holding worker resources.
- `POST /api/lab/scenarios/07-asyncio-cpu-starvation?ms=5000`: Synchronous compute blocking ASGI loop.
