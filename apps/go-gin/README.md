# Failure Lab — Go (`net/http` + `otelhttp`, Stock OTel)

Lean Go HTTP microservice instrumented via `go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp` and configured solely through Formatio's `OTEL_*` environment variables, covering Go concurrency/memory chaos, Automatic Fix PR fixtures, and multi-service trace cascades.

## Deploy on Formatio

- **Option A — Railpack (from repo root):** keep Directory empty and select `railpack.go.json`.
- **Option B — Dockerfile:** set Directory to `apps/go-gin` and Dockerfile to `apps/go-gin/Dockerfile` on port **`8080`**.
- Enable **Settings › Tracing → Enable tracing** before deploying.

### Mesh & Fix PR highlights

- **Scenario 17 / 18 (`POST /orders`, `GET /api/dashboard`, `GET /internal/rates`):** set `PAYMENTS_URL=http://<python-app-name>:8000` (or `PYTHON_URL`).
- **Scenario 12 Fix PR (`GET /ai-sre/shipping-total?pickup=1`):** triggers a clean nil-pointer panic inside `apps/go-gin/shipping_total.go`.
- **Scenario 06 (`POST /api/lab/scenarios/06-goroutine-leak?count=50000`):** spawns blocked channel goroutines (`NumGoroutine` telemetry visible on `/api/lab/status`).
