# Scenario 02: Upstream connection starvation (15-second hanging webhook)

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Failure classification:** Latency cascade / socket and connection exhaustion  
> **Affected framework:** Node.js / Go  
> **Difficulty:** Intermediate

---

## 1. Failure anatomy

Slow third-party dependencies (payment gateways, webhook targets, LLM APIs) without strict timeouts silently fill reverse-proxy worker pools until healthy routes return `504 Gateway Timeout`.

```text
[Incoming clients] -> [Reverse proxy ingress]
                             │
                POST /api/lab/scenarios/02-hang
                             │
                (Hanging 15s waiting on un-aborted upstream call)
                             ↓
         [Healthy endpoints queue and time out]
```

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
./scenarios/02-connection-starvation-hang/trigger.sh http://localhost:3000
```

### Option B: Direct curl
```bash
curl -i -X POST https://your-app.formatio.cloud/api/lab/scenarios/02-hang
```

---

## 3. Traditional infrastructure vs. Formatio

| Infrastructure layer | Traditional setup (ECS / K8s + Datadog) | Formatio |
| :--- | :--- | :--- |
| **Detection** | Threshold latency alerts fire 5–10 minutes after queue saturation. | OpenTelemetry span waterfall flags the 15s outlier immediately (triggering **Slow responses** alerts when configured). |
| **Context** | Ingress logs show `504` without linking the release commit. | Built-in AI error advisor (works out of the box) ties the slow span directly to the deployment commit. |
| **Resolution** | Engineer manually adds `AbortController` after incident review. | Autonomous AI SRE opens a human-reviewed fix PR applying `AbortSignal.timeout(3000)` and fallback handling. |

---

## 4. The solution patch

Review [`solution.patch`](./solution.patch) in this directory to see the timeout and circuit-breaker fix.
