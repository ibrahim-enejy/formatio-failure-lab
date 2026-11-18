# Scenario 05: Database Connection Pool Lockup (N+1 Query & Pool Starvation)

> **Failure Classification:** Database Connection Saturation / Concurrency Starvation  
> **Affected Framework:** Node.js (Prisma/TypeORM/pg-pool), Python (SQLAlchemy), Go (database/sql)  
> **Difficulty:** Advanced  

---

## 1. Failure Anatomy

In microservices under high concurrency, unoptimized database queries (like N+1 loops, unbounded joins, or transactions left open during slow external API calls) saturate the connection pool.

When all pool connections (typically 5 to 10 connections per container) are checked out and blocked waiting for queries to complete, subsequent incoming requests enter a wait queue:
1. The connection queue grows until connection timeout thresholds (e.g., 5000ms - 10000ms) are exceeded.
2. The application begins throwing `TimeoutError: Timed out fetching a new connection from the connection pool`.
3. Health check endpoints that ping the database immediately fail, leading container orchestrators (ECS / Kubernetes) to kill and restart otherwise healthy containers, causing a cascading outage.

```text
[50 Concurrent Requests] ───> [API Gateway / Ingress]
                                        │
                             [Service (Pool Size: 5)]
                                        │
           Connection 1: [Running 100 sequential queries in loop...]
           Connection 2: [Running 100 sequential queries in loop...]
           Connection 3: [Running 100 sequential queries in loop...]
           Connection 4: [Running 100 sequential queries in loop...]
           Connection 5: [Running 100 sequential queries in loop...]
                                        │
      Remaining 45 Requests: [Blocked in Pool Queue ──> 504 / Pool Timeout]
```

---

## 2. Reproduction Steps

### Option A: Using the CLI Trigger Script
```bash
./scenarios/05-postgres-pool-lockup/trigger.sh http://localhost:3000 20
```

### Option B: Direct cURL
```bash
# Simulates concurrent pool lockup
curl -i -X POST https://your-app.formatio.cloud/api/lab/scenarios/02-hang
```

---

## 3. What Happens on Traditional Infrastructure vs. Formatio

| Traditional APM Setup | Formatio Autonomous SRE |
| :--- | :--- |
| CloudWatch alarms trigger when ECS tasks fail health checks. Database CPU stays at 10%, masking the issue as an application bug. | **Formatio telemetry detects pool queue latency spiking** while correlating it to the specific unindexed query or unreleased transaction handle. |
| Engineer restarts the service, but the pool immediately saturates again as soon as traffic resumes. | **Formatio AI SRE generates a PR** with batch queries (`WHERE id IN (...)`), connection pool tuning, and transaction timeouts. |
