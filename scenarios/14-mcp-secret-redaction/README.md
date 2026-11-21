# Scenario 14: Coding-agent debugging over `/mcp` with names-only secret redaction

> **Track:** Govern (Safe coding agents, secrets and team access)  
> **Formatio docs:** [Coding agents (MCP) setup](https://formatio.cloud/docs/platform/mcp) · [Scoped access tokens](https://formatio.cloud/docs/workspace/access-tokens) · [MCP tools reference](https://formatio.cloud/docs/ai-sre/mcp-reference)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

Developers routinely copy production stack traces and `.env` snippets into AI tools when debugging outages. Giving an external agent blanket cluster access or raw environment dumps exposes API keys, database passwords, and billing credentials.

Formatio solves this with **governed MCP access (`POST /mcp`)**:
- `get_occurrence` and `get_issue` give Cursor, Claude Code, Codex, or Copilot the exact trace waterfall, suspect commit SHA, and file/line frames mapped to their local checkout.
- `get_application` returns `variables[]` and `secrets[]` **key names only**—never plaintext secret values—so agents immediately spot a missing `STRIPE_SECRET_KEY` without ever reading the key itself.

---

## 2. Reproduction steps

### Step 1: Configure dummy secrets in Formatio Vault and trigger the config crash
1. On your Formatio `apps/node-express` service, open **Environment**, add a **Secret** named `STRIPE_SECRET_KEY` with dummy value `sk_test_redacted_demo_12345`, and click **Deploy / Redeploy**.
2. Trigger the config exception:
   ```bash
   ./scenarios/14-mcp-secret-redaction/trigger.sh http://localhost:3000
   ```
   *(Or against your deployed app: `./scenarios/14-mcp-secret-redaction/trigger.sh https://your-app.formatio.cloud`.)*

### Step 2: Query over `/mcp` (proving names-only redaction)
1. In Formatio, open **Settings › Access tokens** and create a token with **Platform access: Read** (`ApplicationsRead`, 30-day expiry).
2. Connect your editor:
   ```sh
   export FORMATIO_MCP_TOKEN="REPLACE_WITH_YOUR_TOKEN"
   claude mcp add -s user --transport http formatio https://formatio.cloud/mcp \
     --header "Authorization: Bearer $FORMATIO_MCP_TOKEN"
   ```
3. Or pass `FORMATIO_MCP_TOKEN` and `FORMATIO_URL=https://formatio.cloud` right into `trigger.sh` to invoke `tools/list`, `list_issues`, and `list_applications` over Streamable HTTP and verify no raw secret values appear:
   ```bash
   FORMATIO_MCP_TOKEN="REPLACE_WITH_YOUR_TOKEN" \
   FORMATIO_URL="https://formatio.cloud" \
     ./scenarios/14-mcp-secret-redaction/trigger.sh https://your-app.formatio.cloud
   ```

---

## 3. Ad-hoc AI pasting vs. Formatio `/mcp` governance

| Security check | Pasting `.env` / logs into AI chat | Formatio `/mcp` |
| :--- | :--- | :--- |
| **Secret exposure** | Raw keys leave laptops and enter chat history | `get_application` returns `variables[]` and `secrets[]` **names only** |
| **Token lifetime** | Long-lived admin PATs shared across tools | Expiring scoped tokens (`30`, `90`, `365` days) with `Cache-Control: no-store` creation |
| **Auditability** | Invisible who ran what in prod | Every write logs the specific token ID that triggered it |

---

## 4. Reference fix

Review [`solution.patch`](./solution.patch) for validating required secret presence at startup instead of crashing on checkout requests.
