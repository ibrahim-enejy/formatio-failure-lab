# Formatio Failure Lab: Next.js 15 starter

Runnable Next.js 15 App Router application pre-wired with Formatio's explicit OpenTelemetry SDK hook (`src/instrumentation.ts`) so SSR rendering errors and Route Handler traces appear inside Formatio **Tools › Traces** and **Tools › Errors** without collector sidecars.

## Why Next.js 15+ uses a 1-line hook

Railpack preloads Node tracing for standard HTTP frameworks, while Next.js handles Server Component and Server Action exceptions internally. Both **Railpack** and **Dockerfile** builds use the 1-line `instrumentation.ts` hook:

1. `npm i https://github.com/overal-x/otel/releases/download/node/v0.1.0/formatio-otel-next-0.1.0.tgz`
2. Export `register` and `onRequestError` from `src/instrumentation.ts`:
   ```ts
   export { register, onRequestError } from '@formatio/otel-next'
   ```
3. Mark `@formatio/otel-node` external in `next.config.ts`:
   ```ts
   serverExternalPackages: ['@formatio/otel-node']
   ```

## Deploy on Formatio

1. In [Formatio Dashboard](https://formatio.cloud/dashboard), open **Applications › New application**, select your forked `formatio-failure-lab` repo, keep **Railpack**, and click **Create application**.
2. **Before clicking `Deploy`, open `Settings`:** set **Directory** to `apps/nextjs-15` (leave **Config file** blank) -> **Save**, and confirm **Tracing** is **Enabled**. *(For Dockerfile instead, set **Build context** to `apps/nextjs-15` and **Dockerfile** to `Dockerfile`.)*
3. Open **Networking › Add domain › Platform subdomain**, set **Target port** to **`3000`**, save, and click **Deploy**.

## Local verification

```bash
npm install
npm run build
PORT=3001 npm run start
```

- Healthy trace: `curl -sS -X POST "http://localhost:3001/api/lab/scenarios/11-otel-sdk-error?healthy=1"`
- Route error span: `curl -sS -X POST http://localhost:3001/api/lab/scenarios/11-otel-sdk-error`
- SSR `onRequestError` exception: `curl -sS "http://localhost:3001/ssr-crash?trigger=1"`
