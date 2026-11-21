# Scenario 15: Scoped `/mcp` permissions and instant `agent_access` kill switch

> **Track:** Govern (Safe coding agents, secrets and team access)  
> **Formatio docs:** [Scoped access tokens](https://formatio.cloud/docs/workspace/access-tokens) · [Team access and SSO](https://formatio.cloud/docs/workspace/access)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

Security leads routinely block AI coding integrations when tokens grant overly broad write permissions or cannot be halted immediately during an incident. Formatio enforces two independent circuit breakers at `POST /mcp`:

1. **Cumulative permission scopes:** A baseline read-only token investigates errors and stack traces (`list_issues`, `get_occurrence`, `get_trace`), whereas `deploy_application`, `rollback_application`, `restart_application`, and `set_env_var` are rejected unless **Platform access: Read and deploy** (`ApplicationsWrite`) was granted at creation.
2. **Organization `agent_access` kill switch:** Organization owners can toggle **agent access** off in one click on organization settings to block every MCP token across the entire organization immediately—without deleting audit trails or token records.

---

## 2. Reproduction steps

### Step 1: Issue a baseline read-only token
1. Open **Settings › Access tokens** inside [Formatio Dashboard](https://formatio.cloud/dashboard).
2. Click **New token**, leave the higher-privilege checkboxes unchecked (**Baseline read-only**), set expiration to `30` days, and copy the secret.

### Step 2: Run the scope & kill-switch probe
```bash
export FORMATIO_MCP_TOKEN="REPLACE_WITH_READONLY_TOKEN"
./scenarios/15-mcp-scopes-and-kill-switch/trigger.sh
```

What this verifies:
- `tools/list` succeeds on your scoped token (note how only read-allowed tools succeed when invoked).
- Calling `deploy_application` with a read-only token is denied—proving least-privilege scope enforcement.

### Step 3: Flip the instant `agent_access` kill switch
1. Open organization settings inside Formatio and toggle **agent access** off.
2. Re-run `./scenarios/15-mcp-scopes-and-kill-switch/trigger.sh`.
3. Every `POST /mcp` request from Cursor, Claude Code, Codex, Copilot, or CLI stops immediately until re-enabled.

---

## 3. Enterprise security checklist: ad-hoc tokens vs. Formatio Govern

| Control | Shared personal access tokens | Formatio Govern |
| :--- | :--- | :--- |
| **Least privilege** | All-or-nothing PAT access | 4 granular scopes (`IssuesRead`, `IssuesWrite`, `ApplicationsRead`, `ApplicationsWrite`) |
| **Expiration** | Non-expiring `.env` tokens forgotten on laptops | Enforced `30`, `90`, `365`-day (or explicit never) expiration |
| **Incident containment** | Hunt through dozens of developer laptops during SEV1 | Single **`agent_access`** organization kill switch blocks every agent instantaneously |
