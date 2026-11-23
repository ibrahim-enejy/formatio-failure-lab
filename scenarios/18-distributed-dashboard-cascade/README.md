# Scenario 18: Deep database outage cascading across 3 services to the frontend

> **Track:** Observability (Multi-service OpenTelemetry trace cascades)  
> **Formatio docs:** [Distributed traces](https://formatio.cloud/docs/observability/traces) · [Error groups and suspect commits](https://formatio.cloud/docs/observability/errors)  
> **Difficulty:** Intermediate

---

## 1. Failure anatomy

`GET /dashboard` on `node-express` walks 3 services deep (`Node -> Go API -> Python loyalty -> Go rates-db`):

```text
Node.js (frontend)     Go (API)                 Python (widgets)          Go (rates)
GET /dashboard ─────────▶ GET /api/dashboard
                          └ load profile
                          ├ GET /recommendations ─▶ ✓ rank items
                          └ GET /loyalty ─────────▶ GET /loyalty
                                                    └ load points
                                                    └ GET /internal/rates ──▶ GET /internal/rates
                                                                              └ query rates-db
                                                                                ✗ connection refused
                                                    ◀── 503 ────────────────
                          ◀── 502 ───────────────── "rates answered 503"
◀── 502 {"error": …} ──── renders error payload without checking response.ok
✗ TypeError: Cannot read properties of undefined (reading 'name')   in renderDashboard
500 to the user
```

The user sees a JavaScript `TypeError` in `renderDashboard`, three hops away from the real root cause (`dial tcp 10.0.4.12:5432: connect: connection refused` inside `query rates-db`).

Inside Formatio:
- Open **Tools › Errors** on `node-express`, select the `TypeError`, and jump straight into its trace waterfall.
- **Tools › Traces** spans all 3 services and labels Go's **`query rates-db`** as **`origin`** above the `503 -> 502 -> 502 -> 500` cascade.

---

## 2. Reproduction steps

```bash
# Trigger 3-service dashboard outage cascade (5x)
./scenarios/18-distributed-dashboard-cascade/trigger.sh http://localhost:3000

# Compare against the healthy end-to-end waterfall (?healthy=1)
./scenarios/18-distributed-dashboard-cascade/trigger.sh http://localhost:3000 3 --healthy
```

---

## 3. Reference fix

Review [`solution.patch`](./solution.patch): check `response.ok` on the upstream `/api/dashboard` fetch so a downstream `502` surfaces gracefully as `502 Bad Gateway` instead of crashing `renderDashboard`.
