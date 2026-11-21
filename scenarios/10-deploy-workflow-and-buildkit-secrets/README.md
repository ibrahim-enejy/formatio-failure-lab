# Scenario 10: Zero-CI deploy workflows and BuildKit build secrets

> **Track:** IDP (Deploy, roll back, persist and automate)  
> **Formatio docs:** [Workflow reference](https://formatio.cloud/docs/automation/reference) · [Environment and secrets](https://formatio.cloud/docs/applications/environment)  
> **Difficulty:** Intermediate

---

## 1. Failure anatomy

Two quiet failure modes hit growing engineering teams almost every week:
1. **CI YAML sprawl:** Maintaining 200+ lines of GitHub Actions build-and-push scripts just to deploy `apps/node-express/**` when `main` changes—while skipping commits that only touch `*.md`.
2. **Leaked build secrets in Docker layers:** Passing `PACKAGE_TOKEN` or npm registry credentials via plain `ARG PACKAGE_TOKEN` or Nixpacks env options bakes secrets straight into image history (`docker history --no-trunc`).

Formatio eliminates the bespoke CI glue with built-in DAG **Workflows** (`git-event`, `condition`, `switch`, `deploy`) supporting `GitHub`, `GitLab`, `Bitbucket`, and `Azure DevOps`—and isolates build-only tokens via ephemeral BuildKit secret mounts (`/run/secrets/<KEY>`).

```text
[git push -> apps/node-express/** changed on main]
      ├── Skip if only *.md changed (!**/*.md)
      ├── condition: {{ trigger.branch }} == 'main'
      └── deploy step: builds Dockerfile with --mount=type=secret,id=PACKAGE_TOKEN
                        (never persisted in image layers)
```

---

## 2. Reproduction and artifacts

This directory includes two ready-to-use Formatio configurations:
- [`workflow.yaml`](./workflow.yaml): Declarative branch + monorepo path filter workflow matching Formatio's visual/YAML workflow engine (`git-event` → `condition` → `deploy`).
- [`Dockerfile.buildkit-secret`](./Dockerfile.buildkit-secret): Multi-stage pattern reading `PACKAGE_TOKEN` ephemerally at `/run/secrets/PACKAGE_TOKEN` instead of leaking an `ARG`.

Run the local validation check:
```bash
./scenarios/10-deploy-workflow-and-buildkit-secrets/trigger.sh
```

### Setting it up in Formatio Dashboard
1. Open **Workflows** and click **New workflow**.
2. Switch to YAML view (or use the visual canvas), paste [`workflow.yaml`](./workflow.yaml), and pick your `connection_id`, `repository_id`, and target `application` UUID from the editor pickers.
3. On your application's **Environment** tab, add any sensitive build token (`PACKAGE_TOKEN`) marked as **Secret** (not **Variable**).
4. Push a commit touching `apps/node-express/` on `main` (it deploys) vs. editing only `README.md` (path filter `!**/*.md` ignores it cleanly).

---

## 3. Traditional CI glue vs. Formatio IDP

| Area | Bespoke CI YAML + Docker `ARG` | Formatio workflows + BuildKit secrets |
| :--- | :--- | :--- |
| **Branch & path routing** | Custom `on.push.paths`, OIDC assume-role actions, manual rollout scripts | Native `git-event`, `condition`, `switch`, and `deploy` DAG steps |
| **Git providers** | Rebuilt from scratch per provider (GitHub Actions vs. GitLab CI vs. Bitbucket Pipelines) | Identical workflow graph across `GitHub`, `GitLab`, `Bitbucket`, `Azure DevOps` |
| **Build credential hygiene** | Plain Docker `ARG` stays readable in image history | Mounted ephemerally at `/run/secrets/<KEY>` with BuildKit; never baked into layers |
