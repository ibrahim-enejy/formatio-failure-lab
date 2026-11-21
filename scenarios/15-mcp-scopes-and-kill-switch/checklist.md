# Verification checklist: Scenario 15

- [ ] Read-only baseline token created in **Settings › Access tokens** (`30`, `90`, or `365` days).
- [ ] `tools/list`, `list_issues`, and `get_occurrence` succeed against `POST /mcp`.
- [ ] `deploy_application` returns access denied when called with a read-only token (proves `ApplicationsWrite` separation).
- [ ] Toggling organization **`agent_access`** off in organization settings immediately rejects all further `POST /mcp` requests until restored.
