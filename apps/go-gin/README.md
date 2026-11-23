# Failure Lab — Go (`net/http` + `otelhttp`, Stock OTel)

Lean Go HTTP microservice instrumented via `go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp` and configured solely through Formatio's `OTEL_*` environment variables, covering Go concurrency/memory chaos, Automatic Fix PR fixtures, and multi-service trace cascades.

## Deploy on Formatio

1. In [Formatio Dashboard](https://formatio.cloud/dashboard), open **Applications › New application** inside the same project as `node-express`, name the app **`go-gin`**, pick your forked `formatio-failure-lab` repository, set environment variables below, and click **Create application**.
2. **Before clicking `Deploy`, open `Settings`:**
   - **Option A — Railpack (default):** leave **Directory** blank and set **Config file** to `railpack.go.json` -> **Save**.
   - **Option B — Dockerfile:** set **Build context** to `apps/go-gin` and **Dockerfile** to `Dockerfile` -> **Save**.
   - Confirm **Tracing** is **Enabled**.
3. Keep `go-gin` private on port **`8080`** (no public domain needed for mesh scenarios) and click **Deploy**.

### Mesh & Fix PR highlights

- **Scenario 17 / 18 (`POST /orders`, `GET /api/dashboard`, `GET /internal/rates`):** set `PAYMENTS_URL=http://<python-app-name>:8000` (or `PYTHON_URL`).
- **Scenario 12 Fix PR (`GET /ai-sre/shipping-total?pickup=1`):** triggers a clean nil-pointer panic inside `apps/go-gin/shipping_total.go`.
- **Scenario 06 (`POST /api/lab/scenarios/06-goroutine-leak?count=50000`):** spawns blocked channel goroutines (`NumGoroutine` telemetry visible on `/api/lab/status`).
