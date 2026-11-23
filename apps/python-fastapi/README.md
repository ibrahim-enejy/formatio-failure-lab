# Failure Lab — Python / FastAPI (Stock OTel)

Lean FastAPI ASGI service auto-instrumented via `opentelemetry-instrument` (`opentelemetry-distro` + `fastapi` + `urllib`), preconfigured for Formatio OTLP/HTTP trace ingestion, Python asyncio/OOM chaos, and multi-service distributed traces.

## Deploy on Formatio

- **Option A — Railpack (from repo root):** keep Directory empty and select `railpack.python.json`.
- **Option B — Dockerfile:** set Directory to `apps/python-fastapi` and Dockerfile to `apps/python-fastapi/Dockerfile` on port **`8000`**.
- Enable **Settings › Tracing → Enable tracing** before deploying.

### Mesh endpoints

- **Scenario 17 (`POST /charge`):** payment downstream target called by Go `POST /orders`.
- **Scenario 18 (`GET /recommendations`, `GET /loyalty`):** widget endpoints; set `GO_URL=http://<go-app-name>:8080` so `/loyalty` fetches `/internal/rates`.
- **Scenario 07 (`POST /api/lab/scenarios/07-asyncio-cpu-starvation?ms=5000`):** synchronous CPU loop stalling the ASGI event loop.
