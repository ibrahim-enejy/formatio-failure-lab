# Scenario 03: Detached Async Unhandled Promise Rejection

> **Failure Classification:** Asynchronous Error / Uncaught Exception  
> **Affected Framework:** Node.js (V8 Event Loop Crash)  
> **Difficulty:** Intermediate  

---

## 1. Failure Anatomy

In modern microservices, background async tasks (like fire-and-forget audits, analytics, or webhook dispatchers) are often invoked outside the main Express `try/catch` request lifecycle.

If an error throws inside a detached Promise without a `.catch()` block, Node.js triggers an `unhandledRejection` event. In Node 16+, unhandled rejections terminate the process with exit code 1 (`UnhandledPromiseRejection: This error originated either by throwing inside of an async function without a catch block...`).

```text
[HTTP Request] → POST /api/lab/scenarios/03-unhandled-rejection
      ↓
202 Accepted returned to client
      ↓ (250ms later in detached Promise)
Database Transaction Timeout throws
      ↓ (No .catch() handler)
Process terminates with exit code 1 (Crash Loop)
```

---

## 2. Reproduction

```bash
curl -i -X POST https://your-app.formatio.cloud/api/lab/scenarios/03-unhandled-rejection
```

---

## 3. What Happens on Traditional Infrastructure vs. Formatio

| Traditional APM Setup | Formatio Autonomous SRE |
| :--- | :--- |
| The HTTP request succeeded (202), so the error is **invisible in standard endpoint latency charts**. Sentry logs an unattached error. | **Formatio links the unhandled rejection directly to the execution context**, capturing stack frame, commit ID, and active traces. |
| Engineer has to search container stderr logs to locate the detached promise. | **Formatio AI SRE opens a PR** attaching explicit `.catch()` error logging or safe task queue boundaries. |
