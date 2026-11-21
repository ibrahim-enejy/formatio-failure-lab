# Scenario 08: Bad release, healthcheck gate and 1-click Git rollback

> **Track:** IDP (Deploy, roll back, persist and automate)  
> **Formatio docs:** [Deployments and restarts](https://formatio.cloud/docs/applications/deployments) · [Builds and images](https://formatio.cloud/docs/applications/builds)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

The most common production deployment outages are not complex concurrency bugs—they are bad rollouts: a new commit binds `127.0.0.1` instead of `0.0.0.0`, fails `/healthz`, or misses a required startup config value.

Formatio runs **start-first** rolling updates paired with healthcheck gating across Docker Swarm, Kubernetes, AWS ECS, Google Cloud Run, and bare-metal SSH hosts. If the new replica fails readiness checks (`/healthz`), Formatio halts cutover so live users stay on the healthy container and gives your team a 1-click **Rollback** to any prior `Successful` Git SHA.

```text
[Push broken commit (SIMULATE_BAD_HEALTHCHECK=true or HOST=127.0.0.1)]
      ↓
[Formatio builds new revision and starts candidate container]
      ↓
[GET /healthz returns HTTP 503 or refuses connections]
      ↓
[Start-first rollout halts — live traffic stays on healthy old task]
      ↓
[1-click Rollback in Deployments rebuilds exact previous Successful SHA]
```

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
# Check /healthz locally (port 3000) or against your Formatio service
./scenarios/08-bad-release-healthcheck-rollback/trigger.sh http://localhost:3000
```

### Option B: Trigger a failing release inside Formatio
1. Deploy `apps/node-express`, `apps/nextjs-15`, `apps/python-fastapi`, or `apps/go-gin` cleanly once so you have a `Successful` baseline commit on **Deployments**.
2. Open the application's **Environment** tab and set:
   ```text
   SIMULATE_BAD_HEALTHCHECK=true
   ```
   *(Or push a commit changing `HOST` to `127.0.0.1` so ingress probes cannot reach the container port.)*
3. Click **Deploy / Redeploy** (and probe `/healthz` with `trigger.sh`).
   > **Builder note:** HTTP `/healthz` gating runs automatically on **Dockerfile** builds (via embedded `HEALTHCHECK`) or when `healthcheck_path: "/healthz"` is set via Formatio's HTTP API. On default **Railpack** builds without an explicit `healthcheck_path`, test rollout blocking by pushing a commit binding `HOST=127.0.0.1` or raising a startup exception instead.
4. Watch Formatio surface `Failed` healthcheck status on **Deployments** alongside startup logs on **Logs › Runtime**.
5. Clear `SIMULATE_BAD_HEALTHCHECK` (or revert the bind commit) and click **Rollback** on your earlier `Successful` Git deployment on **Deployments** (or call `/mcp` `rollback_application`).

---

## 3. Traditional DIY pipelines vs. Formatio IDP

| Layer | DIY GitHub Actions + ECS / K8s | Formatio IDP |
| :--- | :--- | :--- |
| **Traffic protection** | Broken pod or task can enter target group unless custom readiness YAML is maintained per service | Start-first rollout with image/HTTP `/healthz` readiness gating built in |
| **Debug loop** | Switch across Actions logs, CloudWatch, and cluster events | Commit SHA, **Build** logs, **Runtime** logs, and deployment status in one view |
| **Recovery** | Re-run stale CI workflow or manually hunt last container tag (`sha-9f12...`) | 1-click **Rollback** (or MCP `rollback_application`) rebuilds the exact prior `Successful` commit |

---

## 4. The solution patch

Review [`solution.patch`](./solution.patch) in this directory to see the fix from binding localhost (`127.0.0.1`) back to all interfaces (`0.0.0.0`) with an explicit HTTP `200` `/healthz` readiness check.
