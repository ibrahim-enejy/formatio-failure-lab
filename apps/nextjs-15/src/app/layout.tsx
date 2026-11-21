import type { Metadata } from 'next'
import type { ReactNode } from 'react'

export const metadata: Metadata = {
  title: 'Formatio Failure Lab — Next.js 15',
  description:
    'Runnable Next.js 15 App Router service instrumented with the 1-line @formatio/otel-next hook.',
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body
        style={{
          fontFamily: 'system-ui, -apple-system, sans-serif',
          margin: '2rem auto',
          maxWidth: '720px',
          padding: '0 1rem',
          lineHeight: 1.6,
        }}
      >
        {children}
      </body>
    </html>
  )
}
