import type { Manifest } from './manifest'

const SCOPES = 'https://www.googleapis.com/auth/drive.file'
const DISCOVERY_DOC = 'https://www.googleapis.com/discovery/v1/apis/drive/v3/rest'

/** Minimal Google Drive client for reading Breakdex data. */
export class DriveClient {
  private accessToken: string

  constructor(accessToken: string) {
    this.accessToken = accessToken
  }

  /** Find the Breakdex folder in the user's Drive. */
  async findBreakdexFolder(): Promise<string | null> {
    const res = await this.request(
      `/drive/v3/files?q=${encodeURIComponent(
        "name = 'Breakdex' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
      )}&fields=files(id)&pageSize=1`
    )
    const data = await res.json()
    return data.files?.[0]?.id ?? null
  }

  /** Download and parse manifest.json from the Breakdex folder. */
  async fetchManifest(folderId: string): Promise<Manifest | null> {
    // Find manifest.json in folder
    const res = await this.request(
      `/drive/v3/files?q=${encodeURIComponent(
        `name = 'manifest.json' and '${folderId}' in parents and trashed = false`
      )}&fields=files(id)&pageSize=1`
    )
    const data = await res.json()
    const fileId = data.files?.[0]?.id
    if (!fileId) return null

    // Download file content
    const content = await this.request(
      `/drive/v3/files/${fileId}?alt=media`
    )
    return content.json()
  }

  /** Get a streaming URL for a video file by its Drive file ID or name in folder. */
  async getVideoUrl(folderId: string, contentHash: string): Promise<string | null> {
    // Find the video file by content hash name
    const res = await this.request(
      `/drive/v3/files?q=${encodeURIComponent(
        `name contains '${contentHash}' and '${folderId}' in parents and trashed = false`
      )}&fields=files(id,name)&pageSize=1`
    )
    const data = await res.json()
    const fileId = data.files?.[0]?.id
    if (!fileId) return null

    // Return a URL that can stream the video (requires auth header)
    return `https://www.googleapis.com/drive/v3/files/${fileId}?alt=media`
  }

  /** List all files in the Breakdex folder. */
  async listFiles(folderId: string): Promise<Array<{ id: string; name: string; size: string }>> {
    const res = await this.request(
      `/drive/v3/files?q=${encodeURIComponent(
        `'${folderId}' in parents and trashed = false`
      )}&fields=files(id,name,size)&pageSize=1000`
    )
    const data = await res.json()
    return data.files ?? []
  }

  /** Get the access token for use in video src URLs. */
  getAccessToken(): string {
    return this.accessToken
  }

  private async request(path: string): Promise<Response> {
    const res = await fetch(`https://www.googleapis.com${path}`, {
      headers: { Authorization: `Bearer ${this.accessToken}` },
    })
    if (!res.ok) {
      throw new Error(`Drive API error: ${res.status} ${res.statusText}`)
    }
    return res
  }
}

/** Google OAuth configuration. Uses the same client ID as the mobile app. */
export const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || ''
export const GOOGLE_SCOPES = SCOPES
