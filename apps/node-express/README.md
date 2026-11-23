# Failure Lab — Node.js / Express 5 (Stock OTel)

Lean Express 5 service auto-instrumented via `@opentelemetry/auto-instrumentations-node/register`, preconfigured to speak OTLP/HTTP traces directly to Formatio and expose every Node.js Failure Lab, Automatic Fix PR, and multi-service distributed trace scenario.

## Deploy on Formatio

- **Option A — Railpack (from repo root):** keep Directory empty and select `railpack.node.json`.
- **Option B — Dockerfile:** set Directory to `apps/node-express` and Dockerfile to `apps/node-express/Dockerfile` on port **`3000`**.
- Enable **Settings › Tracing → Enable tracing** before deploying.

### Optional mesh environment variables

For **Scenario 17 (`/checkout`)** and **Scenario 18 (`/dashboard`)** inside the same Formatio project:

- `ORDERS_URL=http://<go-app-name>:8080` (or `GO_URL=http://<go-app-name>:8080`)
- `DOWNSTREAM_URL=http://<python-app-name>:8000`
