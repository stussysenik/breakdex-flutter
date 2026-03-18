'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { DriveClient } from '@/lib/drive-client'
import type { Manifest, ManifestMove } from '@/lib/manifest'
import { categoryColor, FSRS_STATE_LABELS } from '@/lib/manifest'

export default function LibraryPage() {
  const router = useRouter()
  const [manifest, setManifest] = useState<Manifest | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [folderId, setFolderId] = useState<string | null>(null)
  const [filter, setFilter] = useState<string>('all')

  useEffect(() => {
    // Extract token from URL hash (OAuth implicit flow redirect)
    const hash = window.location.hash
    if (hash) {
      const params = new URLSearchParams(hash.substring(1))
      const token = params.get('access_token')
      if (token) {
        sessionStorage.setItem('gdrive_token', token)
        window.history.replaceState({}, '', '/library')
      }
    }

    const token = sessionStorage.getItem('gdrive_token')
    if (!token) {
      router.push('/')
      return
    }

    loadManifest(token)
  }, [router])

  async function loadManifest(token: string) {
    try {
      const client = new DriveClient(token)
      const folder = await client.findBreakdexFolder()
      if (!folder) {
        setError('No Breakdex folder found in your Google Drive. Make sure you\'ve synced from the app.')
        setLoading(false)
        return
      }
      setFolderId(folder)

      const data = await client.fetchManifest(folder)
      if (!data) {
        setError('manifest.json not found. Sync your library from the Breakdex app first.')
        setLoading(false)
        return
      }

      setManifest(data)
    } catch (e: any) {
      if (e.message?.includes('401')) {
        sessionStorage.removeItem('gdrive_token')
        router.push('/')
        return
      }
      setError(e.message || 'Failed to load library')
    } finally {
      setLoading(false)
    }
  }

  const categories = manifest?.categories ?? []
  const moves = manifest?.moves ?? []
  const fsrsMap = new Map(
    (manifest?.fsrsCards ?? []).map(c => [c.entityId, c])
  )

  const filteredMoves = filter === 'all'
    ? moves
    : moves.filter(m => m.category === filter)

  if (loading) {
    return (
      <main style={styles.container}>
        <p style={{ color: '#a1a1aa' }}>Loading your library...</p>
      </main>
    )
  }

  if (error) {
    return (
      <main style={styles.container}>
        <p style={{ color: '#ef4444' }}>{error}</p>
        <button onClick={() => router.push('/')} style={styles.backButton}>
          Back to Sign In
        </button>
      </main>
    )
  }

  return (
    <main style={{ padding: '1.5rem', maxWidth: '1200px', margin: '0 auto' }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '1.5rem',
      }}>
        <div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 700, margin: 0 }}>
            Breakdex
          </h1>
          <p style={{ color: '#71717a', fontSize: '0.8rem', margin: '0.25rem 0 0' }}>
            {moves.length} moves &middot; Updated {manifest?.exportedAt
              ? new Date(manifest.exportedAt).toLocaleDateString()
              : 'unknown'}
          </p>
        </div>
        <button
          onClick={() => {
            sessionStorage.removeItem('gdrive_token')
            router.push('/')
          }}
          style={{
            padding: '0.5rem 1rem',
            background: 'transparent',
            border: '1px solid #27272a',
            borderRadius: '0.375rem',
            color: '#a1a1aa',
            cursor: 'pointer',
            fontSize: '0.8rem',
          }}
        >
          Sign Out
        </button>
      </div>

      {/* Category filter */}
      <div style={{
        display: 'flex',
        gap: '0.5rem',
        marginBottom: '1.5rem',
        flexWrap: 'wrap',
      }}>
        <FilterChip
          label="All"
          active={filter === 'all'}
          onClick={() => setFilter('all')}
        />
        {categories.map(cat => (
          <FilterChip
            key={cat.name}
            label={cat.name}
            active={filter === cat.name}
            color={categoryColor(cat.colorValue)}
            onClick={() => setFilter(cat.name)}
          />
        ))}
      </div>

      {/* Move grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
        gap: '1rem',
      }}>
        {filteredMoves.map(move => (
          <MoveCard
            key={move.id}
            move={move}
            fsrsState={fsrsMap.get(move.id)?.state}
            folderId={folderId!}
            category={categories.find(c => c.name === move.category)}
          />
        ))}
      </div>

      {filteredMoves.length === 0 && (
        <p style={{ color: '#52525b', textAlign: 'center', marginTop: '3rem' }}>
          No moves in this category
        </p>
      )}
    </main>
  )
}

function FilterChip({
  label,
  active,
  color,
  onClick,
}: {
  label: string
  active: boolean
  color?: string
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '0.375rem 0.75rem',
        borderRadius: '999px',
        border: active ? 'none' : '1px solid #27272a',
        background: active ? (color || '#3b82f6') : 'transparent',
        color: active ? '#fff' : '#a1a1aa',
        fontSize: '0.8rem',
        fontWeight: active ? 600 : 400,
        cursor: 'pointer',
        transition: 'all 150ms',
      }}
    >
      {label}
    </button>
  )
}

function MoveCard({
  move,
  fsrsState,
  folderId,
  category,
}: {
  move: ManifestMove
  fsrsState?: number
  folderId: string
  category?: { name: string; colorValue: number }
}) {
  const stateLabel = FSRS_STATE_LABELS[fsrsState ?? 0] || 'New'
  const hasVideo = !!move.contentHash

  return (
    <a
      href={hasVideo ? `/move?id=${move.id}&folder=${folderId}` : undefined}
      style={{
        display: 'block',
        background: '#18181b',
        borderRadius: '0.5rem',
        border: '1px solid #27272a',
        overflow: 'hidden',
        textDecoration: 'none',
        color: 'inherit',
        transition: 'border-color 150ms',
        cursor: hasVideo ? 'pointer' : 'default',
      }}
    >
      {/* Video placeholder */}
      <div style={{
        aspectRatio: '16/9',
        background: '#09090b',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}>
        {hasVideo ? (
          <svg width="32" height="32" viewBox="0 0 24 24" fill="#52525b">
            <path d="M8 5v14l11-7z" />
          </svg>
        ) : (
          <span style={{ color: '#27272a', fontSize: '0.75rem' }}>No video</span>
        )}
      </div>

      {/* Info */}
      <div style={{ padding: '0.75rem' }}>
        <p style={{
          fontSize: '0.875rem',
          fontWeight: 600,
          margin: '0 0 0.25rem',
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}>
          {move.name}
        </p>
        <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
          {category && (
            <span style={{
              fontSize: '0.7rem',
              color: categoryColor(category.colorValue),
              fontWeight: 500,
            }}>
              {category.name}
            </span>
          )}
          <span style={{
            fontSize: '0.65rem',
            color: '#52525b',
            textTransform: 'uppercase',
            letterSpacing: '0.05em',
          }}>
            {stateLabel}
          </span>
        </div>
      </div>
    </a>
  )
}

const styles = {
  container: {
    display: 'flex' as const,
    flexDirection: 'column' as const,
    alignItems: 'center' as const,
    justifyContent: 'center' as const,
    minHeight: '100vh',
    padding: '2rem',
  },
  backButton: {
    marginTop: '1rem',
    padding: '0.5rem 1rem',
    background: '#27272a',
    border: 'none',
    borderRadius: '0.375rem',
    color: '#e4e4e7',
    cursor: 'pointer' as const,
  },
}
