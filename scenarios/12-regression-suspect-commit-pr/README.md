# Scenario 12: 1-line regression, built-in AI error advisor and autonomous fix PR

> **Track:** AI SRE (Suspect-commit PRs and runtime CVEs)  
> **Formatio docs:** [AI error advisor](https://formatio.cloud/docs/ai-sre/ai-advisor) · [Autonomous fix pull requests](https://formatio.cloud/docs/ai-sre/automated-fix-prs) · [AI providers](https://formatio.cloud/docs/ai-sre/ai-providers)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

In real engineering teams, most urgent bugs aren't exotic kernel panics—they are a tiny unguarded property access introduced in yesterday's merge:

```ts
// apps/node-express/src/app/routes/lab/discount.service.ts
const discountRate = input.coupon!.percentOff / 100
```

Calling checkout without `coupon` throws `TypeError: Cannot read properties of undefined (reading 'percentOff')`.

Inside Formatio, the **AI error advisor** and **autonomous fix pull requests** work together cleanly:
1. **Deterministic suspect attribution:** Formatio inspects deploy history and provider blame to score suspect commits (`Line`, `File`, `Range`, `Ownership`, or `None`).
2. **Built-in AI error advisor natively out of the box:** No AI API key is required—leave **Organization › AI** on **Automatic** and set triage to **Suggest** or **Auto**. Formatio sends zero runtime secrets, wraps stack frames and bounded commit diffs inside `--- BEGIN APPLICATION DATA ---`, and diagnoses root cause (`suspect_sha`, `Evidence`, `SuggestedFix`, `NextSteps`). Teams with strict vendor rules can also optionally connect their own provider across **7 backends** (`Anthropic`, `OpenAI`, `Azure OpenAI`, `Gemini`, `Amazon Bedrock`, `Google Vertex AI`, or `OpenAI-compatible`).
3. **Autonomous fix pull request:** Reproduces the failure inside an isolated, network-restricted sandbox with zero production secrets, verifies a patch against tests, and opens a human-reviewed Git pull request on GitHub, GitLab, Bitbucket, or Azure DevOps—never pushing to `main`.

---

## 2. Reproduction steps

### Step 1: Turn on AI error advisor on hosted Formatio
1. Open **Organization › AI** in [Formatio Dashboard](https://formatio.cloud/dashboard).
2. Keep **Provider** set to **Automatic** (uses Formatio's built-in default AI provider out of the box—no key required) and turn triage on.

### Step 2: Fire the 1-line regression
```bash
./scenarios/12-regression-suspect-commit-pr/trigger.sh https://your-app.formatio.cloud
```

*(Or locally against Docker Compose / Node: `./scenarios/12-regression-suspect-commit-pr/trigger.sh http://localhost:3000`.)*

### Step 3: Inspect the full remediation loop
1. Open **Tools › Errors** and select the `TypeError` group.
2. Verify suspect-commit ranking points straight to `discount.service.ts`, read the built-in **AI error advisor** diagnosis, and review the opened **fix pull request** (or export **Copy fix prompt** / invoke `/mcp` `fix_issue` locally).
3. Merge the PR and watch Formatio record **`"fix deployed"`**, then auto-resolve after the 24-hour quiet verification window.

---

## 3. Standalone chat bots vs. Formatio AI SRE

| Capability | External APM + AI chat paste | Formatio AI SRE |
| :--- | :--- | :--- |
| **Setup to first diagnosis** | Purchase extra AI add-on or configure external LLM webhooks manually | Built-in AI error advisor works natively out of the box (**Automatic**); optional BYO across 7 backends |
| **Context quality** | Raw log snippet without deploy revision graph | Error frames + trace waterfall + ±10-line source window + suspect commit diff |
| **Resolution output** | Chat paragraph the engineer still has to apply manually | Sandboxed verified patch opened as a human-reviewed Git pull request (never pushes to `main`) |

---

## 4. The solution patch

Review [`solution.patch`](./solution.patch) to see the minimal null-safe fix in [`discount.service.ts`](../../apps/node-express/src/app/routes/lab/discount.service.ts).
