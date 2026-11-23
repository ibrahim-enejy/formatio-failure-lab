# Scenario 12: 1-line regression, built-in AI error advisor and automatic fix PRs

> **Track:** AI SRE (Suspect-commit PRs and automatic remediation)  
> **Formatio docs:** [AI error advisor](https://formatio.cloud/docs/ai-sre/ai-advisor) · [Automatic fix pull requests](https://formatio.cloud/docs/ai-sre/automated-fix-prs) · [AI providers](https://formatio.cloud/docs/ai-sre/ai-providers)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

In real engineering teams, most urgent production crashes are tiny null/undefined dereferences merged yesterday—not exotic kernel panics:

```js
// apps/node-express/discount.js
function cartTotal(cart) {
  return cart.items.reduce((total, item) => total + item.cents, 0);
}
```
```go
// apps/go-gin/shipping_total.go
cents := quote.Cents // nil pointer panic when ?pickup=1
```

Calling `/ai-sre/cart-total?empty=1`, `POST /api/lab/scenarios/12-regression` (without `coupon`), or Go's `/ai-sre/shipping-total?pickup=1` produces a deterministic stack frame pointing straight to a single small source file (`Line` attribution confidence).

Inside Formatio:
1. **Deterministic suspect attribution:** Formatio links spans directly to `formatio.deployment.id` and `service.version`, ranking suspect commits (`Line`, `File`, `Range`, `Ownership`, or `None`).
2. **Built-in AI error advisor out of the box:** Leave **Organization › AI** on **Automatic**—no API key required (with optional BYO across 7 providers).
3. **Automatic fix pull request:** When **Organization › AI › Automatic fix PRs** is enabled (on by default), Formatio automatically opens a ready-to-review fix PR on a dedicated branch—never pushing directly to `main`.

---

## 2. Reproduction steps

### Step 1: Turn on Automatic fix PRs in Formatio
1. Open **Organization › AI** in [Formatio Dashboard](https://formatio.cloud/dashboard).
2. Keep **Provider** on **Automatic** and ensure **Automatic fix PRs** is enabled (grant GitHub App **Contents** & **Pull requests** read/write access).

### Step 2: Fire the 1-line regression fixtures
```bash
# Node.js fixtures (discount.js)
./scenarios/12-regression-suspect-commit-pr/trigger.sh https://your-node-app.formatio.cloud

# Optional: also fire the Go shipping fixture (shipping_total.go)
GO_TARGET=https://your-go-app.formatio.cloud ./scenarios/12-regression-suspect-commit-pr/trigger.sh http://localhost:3000
```

### Step 3: Inspect the opened fix pull request
1. Open **Tools › Errors** on the deployed app and check the issue's **Automatic fix PR** link (or click **Fix** manually on open issues).
2. Review the PR branch diff against `apps/node-express/discount.js` or `apps/go-gin/shipping_total.go` and run your tests before merging.

---

## 3. Standalone chat bots vs. Formatio AI SRE

| Capability | External APM + AI chat paste | Formatio AI SRE |
| :--- | :--- | :--- |
| **Setup to first diagnosis** | Purchase extra AI add-on or configure external LLM webhooks manually | Built-in AI error advisor works natively out of the box (**Automatic**); optional BYO across 7 backends |
| **Context quality** | Raw log snippet without deploy revision graph | Error frames + `formatio.deployment.id` / `service.version` + ±10-line source window + suspect commit diff |
| **Resolution output** | Chat paragraph the engineer still has to apply manually | Opens a ready-to-review Git pull request automatically on a fix branch (or accepts MCP `submit_fix_proposal`) |

---

## 4. Reference fix

Review [`solution.patch`](./solution.patch) for the minimal null-safe fixes across [`discount.js`](../../apps/node-express/discount.js) and [`shipping_total.go`](../../apps/go-gin/shipping_total.go).
