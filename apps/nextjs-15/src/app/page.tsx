import Link from 'next/link'

export const dynamic = 'force-dynamic'

export default function HomePage() {
  return (
    <main>
      <h1>Formatio Failure Lab — Next.js 15 starter</h1>
      <p>
        This service demonstrates Formatio&apos;s explicit{' '}
        <code>src/instrumentation.ts</code> hook with{' '}
        <code>@formatio/otel-next</code> alongside{' '}
        <code>serverExternalPackages: [&apos;@formatio/otel-node&apos;]</code>.
      </p>

      <h2>Live endpoints</h2>
      <ul>
        <li>
          <Link href="/healthz">/healthz</Link> — Readiness check (returns HTTP
          503 when <code>SIMULATE_BAD_HEALTHCHECK=true</code>)
        </li>
        <li>
          <Link href="/api/lab/status">/api/lab/status</Link> — Runtime status
          and OpenTelemetry hook verification
        </li>
        <li>
          <Link href="/ssr-crash">/ssr-crash</Link> (pass{' '}
          <code>?trigger=1</code> to test SSR <code>onRequestError</code>)
        </li>
        <li>
          <code>POST /api/lab/scenarios/11-otel-sdk-error</code> — Route
          Handler trace and error trigger (<code>?healthy=1</code> returns a
          clean 200 trace)
        </li>
      </ul>
    </main>
  )
}
