export const dynamic = 'force-dynamic'

interface SsrCrashPageProps {
  searchParams: Promise<{ trigger?: string }>
}

export default async function SsrCrashPage({ searchParams }: SsrCrashPageProps) {
  const params = await searchParams
  if (params.trigger === '1') {
    throw new Error(
      'Formatio Failure Lab: Next.js 15 Server Component rendering error triggered via ?trigger=1',
    )
  }

  return (
    <main>
      <h1>Next.js 15 SSR error target</h1>
      <p>
        Append <code>?trigger=1</code> to raise a Server Component exception and
        verify <code>@formatio/otel-next</code> captures it via{' '}
        <code>onRequestError</code> into Formatio Errors.
      </p>
    </main>
  )
}
