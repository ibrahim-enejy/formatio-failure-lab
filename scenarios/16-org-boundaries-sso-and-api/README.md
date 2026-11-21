# Scenario 16: Project isolation, included OIDC/SAML SSO and REST API idempotency

> **Track:** Govern (Safe coding agents, secrets and team access)  
> **Formatio docs:** [Team access and SSO](https://formatio.cloud/docs/workspace/access) · [HTTP API reference](https://formatio.cloud/docs/platform/api) · [Account and billing](https://formatio.cloud/docs/workspace/account)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

Many platforms lock single sign-on (OIDC/SAML SSO) behind `$2,000+/month` Enterprise tiers, blur project-level access boundaries, and skip idempotency keys on deployment APIs so retried webhooks queue duplicate builds.

Formatio includes all three governance guarantees inside the **$200/month flat** organization plan (starting with a 14-day free trial):
- **OIDC / SAML SSO included:** Identity provider login alongside Argon2id email/password auth—zero SSO tax.
- **Organization + project boundaries:** Project-only members access only the projects they are added to (`Git` & `AI` org-level settings stay restricted to organization members).
- **Idempotent 41-route REST API (`/api/.../`):** Bearer authentication with `Idempotency-Key` headers guarantees network retries return the original queued deployment job instead of double-deploying, while mismatched payloads cleanly reject with HTTP `409`.

---

## 2. Reproduction and API verification steps

Run the companion script (with optional Formatio API credentials to exercise live routes):

```bash
# Prints API checks locally, or runs live authenticated checks when env vars are set
./scenarios/16-org-boundaries-sso-and-api/trigger.sh
```

To execute live checks against Formatio:
```bash
export FORMATIO_URL="https://formatio.cloud"
export FORMATIO_ACCESS_TOKEN="REPLACE_USER_BEARER_TOKEN"
export ORGANIZATION_ID="REPLACE_ORG_UUID"
./scenarios/16-org-boundaries-sso-and-api/trigger.sh
```

What this verifies:
1. `GET /api/user/me/` returns the authenticated caller profile.
2. `GET /api/application/?organization=$ORGANIZATION_ID&limit=20` confirms API tokens require explicit `organization` or `project` scoping rather than inheriting UI switcher state.
3. Documents the exact `Idempotency-Key` header pattern for `POST /api/application/$APPLICATION_ID/build/`.

---

## 3. Enterprise upsells vs. Formatio Govern

| Governance capability | Typical SaaS / PaaS tiers | Formatio (`$200/month flat`) |
| :--- | :--- | :--- |
| **OIDC / SAML SSO** | Locked behind custom Enterprise pricing ("SSO tax") | Included for every organization with a 14-day free trial |
| **Inventory secret storage** | Shared team env vars | AES-256-GCM records sealed to their scope + pinned SSH host keys (`KeyChanged` halt) |
| **Build API retries** | Retried webhook fires duplicate concurrent deploys | `Idempotency-Key` enforcement with conflict detection (`HTTP 409`) |
