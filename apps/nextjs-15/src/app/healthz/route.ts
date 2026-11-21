import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  if (process.env.SIMULATE_BAD_HEALTHCHECK === 'true') {
    return NextResponse.json(
      {
        status: 'unhealthy',
        framework: 'nextjs-15',
        reason: 'SIMULATE_BAD_HEALTHCHECK=true',
      },
      { status: 503 },
    )
  }

  return NextResponse.json({
    status: 'ok',
    framework: 'nextjs-15',
    uptime_seconds: Math.floor(process.uptime()),
  })
}
