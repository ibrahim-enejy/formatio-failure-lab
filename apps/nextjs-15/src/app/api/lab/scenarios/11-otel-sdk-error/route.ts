import { NextRequest, NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function POST(request: NextRequest) {
  const healthy = request.nextUrl.searchParams.get('healthy') === '1'
  await new Promise((resolve) => setTimeout(resolve, 25))

  if (healthy) {
    return NextResponse.json({
      status: 'ok',
      scenario: '11-otel-paths-and-alerts',
      framework: 'nextjs-15',
      otel_sdk: '@formatio/otel-next',
      message: 'Healthy Route Handler span recorded cleanly.',
    })
  }

  throw new Error(
    'Formatio Failure Lab: Next.js 15 Route Handler exception via @formatio/otel-next (pass ?healthy=1 for clean trace)',
  )
}
