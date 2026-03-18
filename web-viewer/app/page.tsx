'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { GOOGLE_CLIENT_ID, GOOGLE_SCOPES } from '@/lib/drive-client'

/** Landing page with Google Sign-In. */
export default function Home() {
  const router = useRouter()
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Check if already authenticated
    const token = sessionStorage.getItem('gdrive_token')
    if (token) {
      router.push('/library')
    }
  }, [router])

  const handleSignIn = () => {
    if (!GOOGLE_CLIENT_ID) {
      setError('Google Client ID not configured. Set NEXT_PUBLIC_GOOGLE_CLIENT_ID.')
      return
    }

    // Use Google's OAuth 2.0 implicit flow
    const params = new URLSearchParams({
      client_id: GOOGLE_CLIENT_ID,
      redirect_uri: window.location.origin + '/library',
      response_type: 'token',
      scope: GOOGLE_SCOPES,
      prompt: 'consent',
    })

    window.location.href = `https://accounts.google.com/o/oauth2/v2/auth?${params}`
  }

  return (
    <main style={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      padding: '2rem',
    }}>
      <div style={{
        textAlign: 'center',
        maxWidth: '400px',
      }}>
        <h1 style={{
          fontSize: '2.5rem',
          fontWeight: 700,
          letterSpacing: '-0.02em',
          marginBottom: '0.5rem',
        }}>
          Breakdex
        </h1>
        <p style={{
          color: '#a1a1aa',
          fontSize: '1rem',
          marginBottom: '2rem',
          lineHeight: 1.6,
        }}>
          Browse your breaking move library from any browser.
          Sign in with the same Google account connected to Breakdex on your phone.
        </p>

        <button
          onClick={handleSignIn}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.75rem',
            padding: '0.75rem 1.5rem',
            fontSize: '1rem',
            fontWeight: 600,
            color: '#fff',
            background: '#3b82f6',
            border: 'none',
            borderRadius: '0.5rem',
            cursor: 'pointer',
            transition: 'background 150ms',
          }}
          onMouseOver={(e) => (e.currentTarget.style.background = '#2563eb')}
          onMouseOut={(e) => (e.currentTarget.style.background = '#3b82f6')}
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" />
            <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
            <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
            <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
          </svg>
          Sign in with Google
        </button>

        {error && (
          <p style={{ color: '#ef4444', marginTop: '1rem', fontSize: '0.875rem' }}>
            {error}
          </p>
        )}

        <p style={{
          color: '#52525b',
          fontSize: '0.75rem',
          marginTop: '2rem',
        }}>
          Read-only access to your Google Drive &middot; No data is stored on our servers
        </p>
      </div>
    </main>
  )
}
