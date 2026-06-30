// Read-only Google Drive access layer. Every call here is a READ — list, get,
// or media download. No create/update/delete is ever issued.
import {
  normalizeManifest,
  type LibraryManifest,
  type MirrorData,
} from "./types";

const DRIVE = "https://www.googleapis.com/drive/v3";
const FOLDER_NAME = "Breakdex";
const FOLDER_MIME = "application/vnd.google-apps.folder";

class DriveAuthError extends Error {}

async function driveGet(
  path: string,
  token: string,
  params: Record<string, string> = {},
): Promise<Response> {
  const url = new URL(`${DRIVE}${path}`);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const res = await fetch(url.toString(), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 401 || res.status === 403) {
    throw new DriveAuthError(`Drive auth failed (${res.status})`);
  }
  if (!res.ok) {
    throw new Error(`Drive request failed (${res.status}): ${path}`);
  }
  return res;
}

interface DriveFile {
  id: string;
  name: string;
  mimeType?: string;
}

async function findBreakdexFolderId(token: string): Promise<string | null> {
  const res = await driveGet("/files", token, {
    q: `name = '${FOLDER_NAME}' and mimeType = '${FOLDER_MIME}' and trashed = false`,
    fields: "files(id,name)",
    pageSize: "1",
  });
  const data = (await res.json()) as { files?: DriveFile[] };
  return data.files?.[0]?.id ?? null;
}

async function listFolder(token: string, folderId: string): Promise<DriveFile[]> {
  const files: DriveFile[] = [];
  let pageToken: string | undefined;
  do {
    const params: Record<string, string> = {
      q: `'${folderId}' in parents and trashed = false`,
      fields: "nextPageToken, files(id,name,mimeType)",
      pageSize: "1000",
    };
    if (pageToken) params.pageToken = pageToken;
    const res = await driveGet("/files", token, params);
    const data = (await res.json()) as {
      files?: DriveFile[];
      nextPageToken?: string;
    };
    files.push(...(data.files ?? []));
    pageToken = data.nextPageToken;
  } while (pageToken);
  return files;
}

/** Loads the manifest + builds a contentHash→fileId map from the user's Drive. */
export async function loadFromDrive(token: string): Promise<MirrorData> {
  const folderId = await findBreakdexFolderId(token);
  if (!folderId) {
    throw new Error(
      "No Breakdex folder found in this Drive. Sync from the mobile app first.",
    );
  }

  const files = await listFolder(token, folderId);

  const manifestFile = files.find((f) => f.name === "manifest.json");
  if (!manifestFile) {
    throw new Error(
      "Breakdex folder has no manifest.json yet. Sync from the mobile app first.",
    );
  }

  const manifestRes = await driveGet(`/files/${manifestFile.id}`, token, {
    alt: "media",
  });
  const manifest = normalizeManifest(
    (await manifestRes.json()) as LibraryManifest,
  );

  // contentHash → fileId, by the `<hash>.mp4` naming convention.
  const byHash = new Map<string, string>();
  for (const f of files) {
    const dot = f.name.lastIndexOf(".");
    const base = dot === -1 ? f.name : f.name.slice(0, dot);
    if (base && base !== "manifest") byHash.set(base, f.id);
  }

  // contentHash → MIME type, from the manifest's asset records. The mobile app
  // uploads video bytes to Drive without a content type, so Drive serves them as
  // `application/octet-stream`; a <video> element can't decode a blob typed that
  // way. We re-stamp the blob with the manifest's real MIME so playback works.
  const mimeByHash = new Map<string, string>();
  for (const a of manifest.assets) {
    if (a.contentHash && a.mimeType) mimeByHash.set(a.contentHash, a.mimeType);
  }

  // Object-URL cache so re-selecting a move doesn't re-download it.
  const urlCache = new Map<string, string>();

  const resolveVideo = async (
    contentHash: string | null,
  ): Promise<string | null> => {
    if (!contentHash) return null;
    const cached = urlCache.get(contentHash);
    if (cached) return cached;
    const fileId = byHash.get(contentHash);
    if (!fileId) return null;
    const res = await driveGet(`/files/${fileId}`, token, { alt: "media" });
    const raw = await res.blob();
    // Drive serves the bytes as octet-stream; re-stamp with the manifest's MIME
    // (default to video/mp4) so the <video> element can decode the object URL.
    const mime = mimeByHash.get(contentHash) ?? "video/mp4";
    const blob = raw.type.startsWith("video/")
      ? raw
      : new Blob([raw], { type: mime });
    const objectUrl = URL.createObjectURL(blob);
    urlCache.set(contentHash, objectUrl);
    return objectUrl;
  };

  return { manifest, resolveVideo, sourceLabel: "Google Drive" };
}

export { DriveAuthError };
