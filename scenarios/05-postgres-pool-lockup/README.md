# Scenario 05: Database connection pool lockup (N+1 query starvation)

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Failure classification:** Database connection saturation / concurrency starvation  
> **Affected framework:** Node.js, Python  
> **Difficulty:** Advanced

---

## 1. Failure anatomy

N+1 query loops or slow external calls held inside active database transactions saturate fixed-size pools (`5–10` connections), queuing every concurrent request until `TimeoutError` cascades.

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
./scenarios/05-postgres-pool-lockup/trigger.sh http://localhost:3000 20
```

### Option B: Direct curl
```bash
curl -i -X POST https://your-app.formatio.cloud/api/lab/scenarios/02-hang
```

---

## 3. Traditional APM vs. Formatio

| Traditional APM setup | Formatio |
| :--- | :--- |
| Database CPU stays low (~10%) while tasks fail healthchecks, masking pool starvation. | OpenTelemetry spans expose queue wait duration tied directly to the deployed release commit. |
| Manual restart only resets the timer until traffic returns. | Built-in AI error advisor (native out of the box) diagnoses the bottleneck and autonomous AI SRE opens a fix PR with batch queries (`WHERE id IN (...)`) and bounded pool timeouts (patch in [`solution.patch`](./solution.patch)). |
