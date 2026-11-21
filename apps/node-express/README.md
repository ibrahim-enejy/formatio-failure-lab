# Formatio Failure Lab: Node.js and Express service

Runnable Node.js 20+ Express service used as the primary target for Formatio's **5-minute Golden Loop** alongside Python/FastAPI, Go/Gin, and Next.js 15.

---

## Quickstart

### Deploy to Formatio (Railpack or Dockerfile)
1. Fork or push this repository to GitHub.
2. Open [Formatio Dashboard](https://formatio.cloud/dashboard) and click **New application**.
3. Select your forked repository and set **Directory** to `apps/node-express`.
4. Set Networking port to `3000` and click **Deploy**.
   - **Railpack:** Builds `npx prisma generate && npx nx build api --configuration=production`, starts `node dist/api/main.js`, and automatically injects `@formatio/otel-node`.
   - **No Postgres required for `/api/lab/*`:** All healthcheck, storage, observability, regression, and `/mcp` scenarios work out of the box without attaching PostgreSQL (`DATABASE_URL` is used only for full RealWorld article routes).

### Local execution
```bash
npm install
npm run build
npm start
```

### Docker Compose
```bash
# From repository root:
docker compose up -d
```

---

## Live endpoints

- `GET /healthz`: Readiness check (returns HTTP `503` when `SIMULATE_BAD_HEALTHCHECK=true`).
- `GET /api/lab/status`: Live Node.js version, PID, uptime, V8 heap/RSS telemetry, and endpoint index.
- `POST /api/lab/storage` & `GET /api/lab/storage`: Writes and verifies ephemeral (`/tmp`) vs. persistent (`DATA_DIR` / `/data`) markers.
- `POST /api/lab/scenarios/01-oom`: Unbounded heap allocation triggering kernel OOM (`SIGKILL 137`).
- `POST /api/lab/scenarios/02-hang`: 15-second upstream hang demonstrating reverse-proxy connection saturation.
- `POST /api/lab/scenarios/03-unhandled-rejection`: Detached async promise rejection exiting the process cleanly with a 2s OTLP flush.
- `POST /api/lab/scenarios/04-event-loop-block?ms=5000`: Synchronous CPU loop blocking the event loop and `/healthz`.
- `POST /api/lab/scenarios/12-regression`: Deterministic 1-line regression in `discount.service.ts` for AI error advisor and autonomous fix PR testing.
- `POST /api/lab/scenarios/14-secret-crash`: Checks secret presence by name only (never logging raw values) for `/mcp` redaction verification.
