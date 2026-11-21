# Scenario 01: Unbounded heap allocation (OOM kill and crash loop)

> **Track:** Observability (Lightweight OpenTelemetry, traces and alerts)  
> **Failure classification:** Memory leak / Out-of-Memory (OOM)  
> **Affected framework:** Node.js, Python, Go  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

In production microservices, memory leaks often stay invisible until traffic peaks. A batch loop or unbuffered payload continually appends buffers to an in-memory array until the Linux kernel invokes `oom-killer` with `SIGKILL` (`exit code 137`).

```text
[HTTP request] -> POST /api/lab/scenarios/01-oom
      ↓
Allocating 10 MB chunks continuously
      ↓
V8 heap limit or container cgroup limit exceeded
      ↓
Linux kernel sends SIGKILL (exit code 137) -> App crashed alert fires
```

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
# Target local instance
./scenarios/01-heap-oom-crash/trigger.sh http://localhost:3000

# Target Formatio live deployment
./scenarios/01-heap-oom-crash/trigger.sh https://your-app.formatio.cloud
```

### Option B: Direct curl
```bash
curl -X POST https://your-app.formatio.cloud/api/lab/scenarios/01-oom
```

---

## 3. Traditional infrastructure vs. Formatio

| Infrastructure layer | Traditional setup (ECS / K8s + Datadog) | Formatio |
| :--- | :--- | :--- |
| **Detection** | Generic alert: *"Container restarted with exit code 137"*. | Automatic Railpack OpenTelemetry (or 2–3 line SDK hook) captures span and memory telemetry before process death, plus instant **App crashed** alerting. |
| **Triage time** | 45–90 minutes reproducing locally or pulling heap dumps. | Built-in AI error advisor (works out of the box, no key needed) and suspect commit ranking pinpoint the unbounded allocation handler. |
| **Resolution** | Manual hotfix after post-mortem. | Autonomous sandboxed fix PR replaces unbounded buffering with bounded streaming, or use `/mcp` `fix_issue` locally. |

---

## 4. The solution patch

Review [`solution.patch`](./solution.patch) in this directory to see the exact bounded-memory fix for `apps/node-express`.
