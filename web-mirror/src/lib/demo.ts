// Demo data source — loads a static sample manifest + sample video from
// /public so the full mirror UI can be verified locally WITHOUT Firebase or
// Drive credentials. Reached via `?demo=1`. Strictly a dev/verification aid;
// it never touches Drive or auth.
import {
  normalizeManifest,
  type LibraryManifest,
  type MirrorData,
} from "./types";

export async function loadDemo(): Promise<MirrorData> {
  const res = await fetch("/sample-manifest.json", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load sample manifest");
  const manifest = normalizeManifest((await res.json()) as LibraryManifest);

  // Every content hash in the sample maps to the one bundled sample clip, so
  // playback is demonstrable end to end.
  const resolveVideo = async (
    contentHash: string | null,
  ): Promise<string | null> => {
    if (!contentHash) return null;
    return "/sample-video.mp4";
  };

  return { manifest, resolveVideo, sourceLabel: "Demo fixture" };
}
