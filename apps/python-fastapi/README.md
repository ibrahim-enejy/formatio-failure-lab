# Failure Lab — Python / FastAPI (Stock OTel)

Lean FastAPI ASGI service auto-instrumented via `opentelemetry-instrument` (`opentelemetry-distro` + `fastapi` + `urllib`), preconfigured for Formatio OTLP/HTTP trace ingestion, Python asyncio/OOM chaos, and multi-service distributed traces.

## Deploy on Formatio

1. In [Formatio Dashboard](https://formatio.cloud/dashboard), open **Applications › New application** inside the same project as `node-express`, name the app **`python-fastapi`**, pick your forked `formatio-failure-lab` repository, set environment variables below, and click **Create application**.
2. **Before clicking `Deploy`, open `Settings`:**
   - **Option A — Railpack (default):** leave **Directory** blank and set **Config file** to `railpack.python.json` -> **Save**.
   - **Option B — Dockerfile:** set **Build context** to `apps/python-fastapi` and **Dockerfile** to `Dockerfile` -> **Save**.
   - Confirm **Tracing** is **Enabled**.
3. Keep `python-fastapi` private on port **`8000`** (no public domain needed for mesh scenarios) and click **Deploy**.

### Mesh endpoints

- **Scenario 17 (`POST /charge`):** payment downstream target called by Go `POST /orders`.
- **Scenario 18 (`GET /recommendations`, `GET /loyalty`):** widget endpoints; set `GO_URL=http://<go-app-name>:8080` so `/loyalty` fetches `/internal/rates`.
- **Scenario 07 (`POST /api/lab/scenarios/07-asyncio-cpu-starvation?ms=5000`):** synchronous CPU loop stalling the ASGI event loop.
