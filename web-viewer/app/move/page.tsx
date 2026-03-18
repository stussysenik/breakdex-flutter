'use client'

import { useEffect, useState, useRef, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { DriveClient } from '@/lib/drive-client'
import type { Manifest, ManifestMove, ManifestReview } from '@/lib/manifest'
import { FSRS_STATE_LABELS } from '@/lib/manifest'

function MoveDetailContent() {
  const router = useRouter()
  const params = useSearchParams()
  const moveId = params.get('id')
  const folderId = params.get('folder')

  const [manifest, setManifest] = useState<Manifest | null>(null)
  const [videoUrl, setVideoUrl] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const videoRef = useRef<HTMLVideoElement>(null)

  useEffect(() => {
    const token = sessionStorage.getItem('gdrive_token')
    if (!token || !moveId || !folderId) {
      router.push('/')
      return
    }

    loadMoveData(token)
  }, [moveId, folderId, router])

  async function loadMoveData(token: string) {
    try {
      const client = new DriveClient(token)

      // Load manifest for move metadata
      const data = await client.fetchManifest(folderId!)
      if (!data) {
        router.push('/library')
        return
      }
      setManifest(data)

      // Find the move
      const move = data.moves.find(m => m.id === moveId)
      if (!move?.contentHash) {
        setLoading(false)
        return
      }

      // Get video streaming URL
      const url = await client.getVideoUrl(folderId!, move.contentHash)
      if (url) {
        // Append access token for authenticated streaming
        setVideoUrl(`${url}&access_token=${token}`)
      }
    } catch (e: any) {
      if (e.message?.includes('401')) {
        sessionStorage.removeItem('gdrive_token')
        router.push('/')
        return
      }
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <main style={styles.center}>
        <p style={{ color: '#a1a1aa' }}>Loading move...</p>
      </main>
    )
  }

  const move = manifest?.moves.find(m => m.id === moveId)
  if (!move) {
    return (
      <main style={styles.center}>
        <p style={{ color: '#ef4444' }}>Move not found</p>
      </main>
    )
  }

  const fsrsCard = manifest?.fsrsCards.find(
    c => c.entityId === moveId && c.entityType === 'move'
  )
  const reviews = (manifest?.reviews ?? []).filter(
    r => r.entityId === moveId
  )
  const stateLabel = FSRS_STATE_LABELS[fsrsCard?.state ?? 0] || 'New'

  return (
    <main style={{ maxWidth: '800px', margin: '0 auto', padding: '1.5rem' }}>
      {/* Back button */}
      <button
        onClick={() => router.push(`/library`)}
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '0.25rem',
          background: 'none',
          border: 'none',
          color: '#71717a',
          cursor: 'pointer',
          padding: 0,
          fontSize: '0.875rem',
          marginBottom: '1rem',
        }}
      >
        ← Back to Library
      </button>

      {/* Video player */}
      {videoUrl ? (
        <div style={{
          borderRadius: '0.5rem',
          overflow: 'hidden',
          background: '#09090b',
          marginBottom: '1.5rem',
        }}>
          <video
            ref={videoRef}
            src={videoUrl}
            controls
            playsInline
            style={{ width: '100%', display: 'block' }}
          />
        </div>
      ) : (
        <div style={{
          aspectRatio: '16/9',
          background: '#09090b',
          borderRadius: '0.5rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '1.5rem',
        }}>
          <p style={{ color: '#27272a' }}>No video available</p>
        </div>
      )}

      {/* Move info */}
      <h1 style={{
        fontSize: '1.75rem',
        fontWeight: 700,
        margin: '0 0 0.5rem',
      }}>
        {move.name}
      </h1>

      <div style={{
        display: 'flex',
        gap: '1rem',
        alignItems: 'center',
        marginBottom: '1.5rem',
      }}>
        <span style={{
          fontSize: '0.8rem',
          color: '#a1a1aa',
          padding: '0.25rem 0.75rem',
          background: '#27272a',
          borderRadius: '999px',
        }}>
          {move.category}
        </span>
        <span style={{
          fontSize: '0.75rem',
          color: '#71717a',
          textTransform: 'uppercase',
          letterSpacing: '0.05em',
        }}>
          {stateLabel}
        </span>
        <span style={{ fontSize: '0.75rem', color: '#52525b' }}>
          Added {new Date(move.createdAt).toLocaleDateString()}
        </span>
      </div>

      {/* FSRS stats */}
      {fsrsCard && (
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: '1rem',
          marginBottom: '1.5rem',
        }}>
          <StatBox label="Stability" value={fsrsCard.stability?.toFixed(1) ?? '-'} />
          <StatBox label="Difficulty" value={fsrsCard.difficulty?.toFixed(1) ?? '-'} />
          <StatBox label="Due" value={
            new Date(fsrsCard.due).toLocaleDateString()
          } />
        </div>
      )}

      {/* Recent reviews */}
      {reviews.length > 0 && (
        <>
          <h2 style={{
            fontSize: '1rem',
            fontWeight: 600,
            margin: '0 0 0.75rem',
            color: '#a1a1aa',
          }}>
            Recent Reviews ({reviews.length})
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {reviews.slice(0, 10).map(review => (
              <ReviewRow key={review.id} review={review} />
            ))}
          </div>
        </>
      )}
    </main>
  )
}

export default function MovePage() {
  return (
    <Suspense fallback={
      <main style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
      }}>
        <p style={{ color: '#a1a1aa' }}>Loading...</p>
      </main>
    }>
      <MoveDetailContent />
    </Suspense>
  )
}

function StatBox({ label, value }: { label: string; value: string }) {
  return (
    <div style={{
      background: '#18181b',
      borderRadius: '0.5rem',
      padding: '0.75rem',
      border: '1px solid #27272a',
    }}>
      <p style={{
        fontSize: '0.65rem',
        color: '#52525b',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        margin: '0 0 0.25rem',
      }}>
        {label}
      </p>
      <p style={{ fontSize: '1.125rem', fontWeight: 600, margin: 0 }}>
        {value}
      </p>
    </div>
  )
}

function ReviewRow({ review }: { review: ManifestReview }) {
  const ratingColors: Record<string, string> = {
    AGAIN: '#ef4444',
    HARD: '#f59e0b',
    GOOD: '#22c55e',
    EASY: '#3b82f6',
  }

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      padding: '0.5rem 0.75rem',
      background: '#18181b',
      borderRadius: '0.375rem',
      border: '1px solid #27272a',
    }}>
      <span style={{
        fontSize: '0.8rem',
        fontWeight: 600,
        color: ratingColors[review.rating] || '#a1a1aa',
      }}>
        {review.rating}
      </span>
      <span style={{ fontSize: '0.75rem', color: '#52525b' }}>
        {new Date(review.createdAt).toLocaleDateString()}
      </span>
    </div>
  )
}

const styles = {
  center: {
    display: 'flex' as const,
    alignItems: 'center' as const,
    justifyContent: 'center' as const,
    minHeight: '100vh',
  },
}
