import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Breakdex — Web Viewer',
  description: 'Browse your breaking move library from any browser',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body style={{
        margin: 0,
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        background: '#0a0a0a',
        color: '#e4e4e7',
        minHeight: '100vh',
      }}>
        {children}
      </body>
    </html>
  )
}
