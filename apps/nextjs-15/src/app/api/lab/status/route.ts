import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  const mem = process.memoryUsage()
  return NextResponse.json({
    status: 'online',
    app: 'Formatio Failure Lab — Next.js 15 App Router',
    otel_sdk: '@formatio/otel-next (src/instrumentation.ts)',
    runtime: {
      node: process.version,
      platform: process.platform,
      uptime_seconds: Math.floor(process.uptime()),
    },
    memory: {
      rss_mb: Math.round((mem.rss / 1024 / 1024) * 100) / 100,
      heap_used_mb: Math.round((mem.heapUsed / 1024 / 1024) * 100) / 100,
    },
    scenarios: {
      '08-healthcheck': 'GET /healthz',
      '11-otel-sdk-ssr': 'GET /ssr-crash?trigger=1',
      '11-otel-sdk-route': 'POST /api/lab/scenarios/11-otel-sdk-error',
    },
  })
}
