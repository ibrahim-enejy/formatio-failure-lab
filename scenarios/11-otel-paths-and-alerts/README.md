# Scenario 11: Railpack auto-instrumentation vs. 1-line SDK hook and alerting

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Formatio docs:** [Tracing setup and SDKs](https://formatio.cloud/docs/observability/sdks) · [Alerts](https://formatio.cloud/docs/observability/alerts)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

Most OpenTelemetry setups stall for weeks because teams assume they have to either maintain collector sidecars or rewrite every microservice handler. Formatio splits instrumentation cleanly into two honest paths—both exporting standard OTLP (`http/protobuf`) to `/otlp/v1/traces` with zero sidecars:

1. **Path A — Automatic Railpack injection:** Supported **Railpack** builds (`Go`, `Node.js 18.19+`, `Python 3.10+`, `Java`, `C#/.NET 8+`) inject instrumentation into `/opt/formatio` automatically at build time (`apps/node-express`, `apps/python-fastapi`, `apps/go-gin`). Build logs confirm `formatio: tracing added with <package>` or `formatio: tracing compiled in`.
2. **Path B — Explicit 1–3 line Formatio SDK hook:** For **Next.js 15+**, **Fastify**, **Dockerfiles**, or **Nixpacks**, add the lightweight package once—demonstrated live in [`apps/nextjs-15`](../../apps/nextjs-15/src/instrumentation.ts) with `@formatio/otel-next` (`export { register, onRequestError } from '@formatio/otel-next'`).

Every runtime exception or `5xx` error group immediately evaluates organization rules under **Tools › Alerts** and notifies **Slack**, **Microsoft Teams**, **PagerDuty**, **Opsgenie**, **Discord**, or custom HMAC-signed HTTPS webhooks (`Formatio-Signature`, `Formatio-Delivery`).

---

## 2. Reproduction steps

### Step 1: Test automatic Railpack service (`apps/node-express`) vs. Next.js 15 SDK hook (`apps/nextjs-15`)
```bash
# Default local Next.js 15 target on port 3001 (or pass your deployed Formatio URL)
./scenarios/11-otel-paths-and-alerts/trigger.sh http://localhost:3001
```

### Step 2: Connect an alert destination in Formatio
1. Open **Tools › Alerts › Integrations › Add integration** in [Formatio Dashboard](https://formatio.cloud/dashboard) and connect **Slack**, **Discord**, **Microsoft Teams**, **PagerDuty**, **Opsgenie**, or an **HTTPS webhook**.
2. Notice **Deployment failed** and **App crashed** rules are active out of the box; enable **New error** and **Error came back** for full regression coverage.
3. Trigger `POST /api/lab/scenarios/11-otel-sdk-error` or `GET /ssr-crash?trigger=1` on `apps/nextjs-15` to watch the distributed span waterfall under **Tools › Traces**, the grouped issue under **Tools › Errors**, and the alert delivery arrive with commit context.

---

## 3. Stitched observability vs. Formatio observability

| Capability | Collector sidecars + manual APM | Formatio lightweight OpenTelemetry |
| :--- | :--- | :--- |
| **Supported runtimes** | Heavy DaemonSet or vendor-proprietary agent per host | Automatic Railpack injection (`Go`, `Node.js`, `Python`, `Java`, `.NET`) + 1–3 line SDKs (`Next.js 15+`, `Dockerfile`) |
| **Crash safety** | Async buffers often drop process-exit exceptions | Uncaught exceptions emit `uncaught exception` span with up to 2s OTLP flush |
| **Alert routing** | Separate alerting tool with extra webhook scripts | 6 native alert integrations (`Slack`, `Teams`, `PagerDuty`, `Opsgenie`, `Discord`, signed HTTP) built in |
| **Pricing surprise** | Per-host, per-GB ingested, and per-seat multipliers | Included inside **$200/month flat** per organization |

---

## 4. Hook configuration and reference patch

- Instrumentation hook is already wired in [`src/instrumentation.ts`](../../apps/nextjs-15/src/instrumentation.ts) (`export { register, onRequestError } from '@formatio/otel-next'`) and [`next.config.ts`](../../apps/nextjs-15/next.config.ts).
- Review [`solution.patch`](./solution.patch) to see a handled `500` JSON fix for the demo Route Handler [`route.ts`](../../apps/nextjs-15/src/app/api/lab/scenarios/11-otel-sdk-error/route.ts) (`git apply --check scenarios/11-otel-paths-and-alerts/solution.patch`).
