# Scenario 03: Detached async unhandled promise rejection

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Failure classification:** Asynchronous error / uncaught exception  
> **Affected framework:** Node.js  
> **Difficulty:** Intermediate

---

## 1. Failure anatomy

Background async tasks (audit logging, webhook dispatching) often run outside Express request `try/catch` blocks. An unawaited rejection throws an `unhandledRejection` after `202 Accepted` already returned, exiting Node.js with status `1`.

```text
[HTTP request] -> POST /api/lab/scenarios/03-unhandled-rejection
      ↓
202 Accepted returned to client
      ↓ (250ms later inside detached Promise)
Database transaction timeout throws -> uncaught exception 2s OTLP flush -> exit code 1
```

---

## 2. Reproduction

```bash
./scenarios/03-unhandled-promise-rejection/trigger.sh http://localhost:3000
```

Direct curl:
```bash
curl -i -X POST https://your-app.formatio.cloud/api/lab/scenarios/03-unhandled-rejection
```

---

## 3. Traditional APM vs. Formatio

| Traditional APM setup | Formatio |
| :--- | :--- |
| Request already returned `202`, hiding failure in latency charts while the process exits before async log shippers flush. | `@formatio/otel-node` emits an `uncaught exception` span with up to a 2-second OTLP flush before exit, tying stack frames to the deployed commit. |
| Engineer scrapes container stderr logs manually to locate the detached promise. | Built-in AI error advisor explains the detached rejection out of the box and AI SRE opens a human-reviewed fix PR adding explicit `.catch()` error handling (patch in [`solution.patch`](./solution.patch)). |
