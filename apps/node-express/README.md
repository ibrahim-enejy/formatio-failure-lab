# Failure Lab — Node.js / Express 5 (Stock OTel)

Lean Express 5 service auto-instrumented via `@opentelemetry/auto-instrumentations-node/register`, preconfigured to speak OTLP/HTTP traces directly to Formatio and expose every Node.js Failure Lab, Automatic Fix PR, and multi-service distributed trace scenario.

## Deploy on Formatio

1. In [Formatio Dashboard](https://formatio.cloud/dashboard), open **Applications › New application**, name the app **`node-express`**, pick your forked `formatio-failure-lab` repository, set environment variables below, and click **Create application**.
2. **Before clicking `Deploy`, open `Settings`:**
   - **Option A — Railpack (default):** leave **Directory** blank and set **Config file** to `railpack.node.json` -> **Save**.
   - **Option B — Dockerfile:** set **Build context** to `apps/node-express` and **Dockerfile** to `Dockerfile` -> **Save**.
   - Confirm **Tracing** is **Enabled**.
3. Open **Networking › Add domain › Platform subdomain**, enter a short lowercase name, set **Target port** to **`3000`**, and save.
4. Click **Deploy**.

### Optional mesh environment variables

For **Scenario 17 (`/checkout`)** and **Scenario 18 (`/dashboard`)** inside the same Formatio project:

- `ORDERS_URL=http://<go-app-name>:8080` (or `GO_URL=http://<go-app-name>:8080`)
- `DOWNSTREAM_URL=http://<python-app-name>:8000`
