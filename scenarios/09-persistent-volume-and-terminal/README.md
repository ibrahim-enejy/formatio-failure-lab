# Scenario 09: Persistent volume survival and browser terminal

> **Track:** IDP (Deploy, roll back, persist and automate)  
> **Formatio docs:** [Persistent storage](https://formatio.cloud/docs/applications/storage) · [Container terminal](https://formatio.cloud/docs/applications/terminal)  
> **Difficulty:** Beginner

---

## 1. Failure anatomy

Container filesystems reset whenever a deployment or restart replaces a task. Teams often notice this only after losing uploaded files, SQLite/Postgres state, or job queues right after a routine push.

Formatio solves both sides cleanly:
1. **Named volumes** mounted at a dedicated data path (for example `/data`) preserve files untouched across **Deploy / Redeploy** and **Restart** operations without shadowing application code under `/app`.
2. **Browser Terminal** lets authorized engineers inspect mounted paths live inside the running container without SSH bastions or distributing PEM keys.

```text
[POST /api/lab/storage]
      ├── Writes /tmp/formatio-ephemeral.json        (wipes on redeploy)
      └── Writes /data/formatio-persistent.json      (survives when volume mounted)
            ↓
[Run Deploy / Redeploy in Formatio Dashboard]
            ↓
[GET /api/lab/storage]
      ├── ephemeral_present:  false
      └── persistent_present: true   <-- verified in app + browser Terminal
```

---

## 2. Reproduction steps

### Option A: Using the CLI trigger script
```bash
# Write markers before redeploy
./scenarios/09-persistent-volume-and-terminal/trigger.sh https://your-app.formatio.cloud

# Verify markers after redeploy (pass verify as second argument)
./scenarios/09-persistent-volume-and-terminal/trigger.sh https://your-app.formatio.cloud verify
```

### Option B: Full Formatio Dashboard walkthrough
1. Deploy `apps/node-express` on Formatio.
2. Open the application's **Volumes** tab and click **Add volume**:
   - **Name:** `lab-data`
   - **Mount path:** `/data` *(keep `/app` untouched so container binaries/dist aren't shadowed)*
3. Set `DATA_DIR=/data` on **Environment** and click **Deploy / Redeploy**.
4. Write both markers:
   ```bash
   curl -fsS -X POST https://your-app.formatio.cloud/api/lab/storage
   ```
5. Click **Deploy / Redeploy** again to force a fresh container replacement.
6. Verify `/tmp` wiped while `/data` survived:
   ```bash
   curl -fsS https://your-app.formatio.cloud/api/lab/storage
   ```
7. Open Formatio's **Terminal** tab on the running application and run:
   ```sh
   cat /data/formatio-persistent.json && ls -la /tmp/formatio-ephemeral.json
   ```

---

## 3. Traditional DIY infrastructure vs. Formatio IDP

| Operations task | Raw host SSH / Kubernetes PV YAML | Formatio IDP |
| :--- | :--- | :--- |
| **Attach state** | Hand-write PVC manifests or edit host bind mounts in Ansible/Compose | Enter `lab-data` and `/data` on **Volumes** and redeploy |
| **Avoid image shadowing** | Easy to mount over `/app` and break startup silently | Explicit warning and separate `/data` mount convention |
| **Live inspection** | Bastion hop, SSH key distribution, or `kubectl exec` RBAC | Instant browser **Terminal** in the same application panel |

---

## 4. Reference fix

Review [`solution.patch`](./solution.patch) for migrating ephemeral `/tmp` writes onto the mounted `/data` volume directory (`DATA_DIR`).
