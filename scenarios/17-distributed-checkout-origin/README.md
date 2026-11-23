# Scenario 17: Swallowed frontend error causing a downstream crash (`origin` isolation)

> **Track:** Observability (Multi-service OpenTelemetry trace cascades)  
> **Formatio docs:** [Distributed traces](https://formatio.cloud/docs/observability/traces) · [Error groups and suspect commits](https://formatio.cloud/docs/observability/errors)  
> **Difficulty:** Intermediate

---

## 1. Failure anatomy

`GET /checkout` on `node-express` walks a real 3-service checkout across **Node.js**, **Go**, and **Python**:

```text
Node.js (frontend)          Go (orders API)              Python (payments)
GET /checkout
 └ price cart  ✗ PriceFormatError: cannot price kb-01: "1,299.00"   ← recorded, then swallowed
 └ POST /orders  { total: null } ─▶ POST /orders
                                  └ reserve inventory
                                  └ POST /charge { amount: null } ─▶ POST /charge
                                                                    └ compute fees ✗ TypeError
                                  └ release inventory  ◀── 500
 ◀── 502 "payment service answered 500"
502 to the user
```

The frontend swallows `PriceFormatError` and forwards `total: null`. Nothing crashes there—the crash blows up two hops downstream inside Python (`compute fees`). Without correlated distributed tracing, the payments team gets paged for the wrong service.

Inside Formatio:
- **Tools › Traces** shows **one** distributed trace spanning all 3 services and labels the frontend `price cart` span as **`origin`**—the first exception in the causal chain.
- **Tools › Errors** links `PriceFormatError` (Node.js) and `TypeError` (Python) to the same trace ID.

---

## 2. Reproduction steps

Deploy all 3 services in one Formatio project (`railpack.node.json`, `railpack.go.json`, `railpack.python.json`, or Docker Compose locally) with tracing enabled, then run:

```bash
# Fire failing distributed checkout trace (5x)
./scenarios/17-distributed-checkout-origin/trigger.sh http://localhost:3000

# Compare against a clean distributed trace (?healthy=1)
./scenarios/17-distributed-checkout-origin/trigger.sh http://localhost:3000 3 --healthy
```

---

## 3. Reference fix

Review [`solution.patch`](./solution.patch): instead of swallowing `PriceFormatError` and sending `total: null` downstream, reject invalid cart prices cleanly with HTTP `400` at the checkout boundary.
