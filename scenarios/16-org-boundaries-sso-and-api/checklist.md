# Verification checklist: Scenario 16

- [ ] Project-only member sees only granted projects while organization **Git** and **AI** settings remain hidden to non-organization members.
- [ ] OIDC / SAML SSO login works alongside email/password inside the `$200/month flat` organization plan (zero Enterprise tier gate).
- [ ] `GET /api/application/` requires explicit `organization` or `project` parameter.
- [ ] Retrying `POST /api/application/{id}/build/` with an identical `Idempotency-Key` and body returns the original queued job (`200`), while changing the payload with the same key returns HTTP `409`.
