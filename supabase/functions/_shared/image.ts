// Pure helpers for check-in images stored in the private `checkins` bucket.
// Path convention: {household_or_user_id}/{project_id}/{uuid}.jpg

const UUID = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
const PATH_RE = new RegExp(`^(${UUID})/(${UUID})/(${UUID})\\.jpg$`, 'i');

/** True when `path` has the expected shape and belongs to `projectId` (and to a folder the caller may use). */
export function isValidShotPath(path: unknown, projectId: string, allowedFolders: string[]): path is string {
  if (typeof path !== 'string') return false;
  const m = PATH_RE.exec(path);
  if (!m) return false;
  return m[2].toLowerCase() === projectId.toLowerCase() && allowedFolders.some((f) => f.toLowerCase() === m[1].toLowerCase());
}

export function toBase64(bytes: Uint8Array): string {
  let bin = '';
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) bin += String.fromCharCode(...bytes.subarray(i, i + chunk));
  return btoa(bin);
}

/** JPEG magic bytes FF D8 FF. */
export function looksLikeJpeg(bytes: Uint8Array): boolean {
  return bytes.length > 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
}

export const SHOT_TYPES = ['whole_plant', 'close_leaf', 'leaf_underside'] as const;

export interface Shot { shot: (typeof SHOT_TYPES)[number]; path: string }

/** Parses checkins.shots ([{shot, path}]) defensively. */
export function parseShots(raw: unknown, projectId: string, allowedFolders: string[], max = 3): Shot[] {
  if (!Array.isArray(raw)) return [];
  const out: Shot[] = [];
  for (const s of raw.slice(0, max)) {
    if (s && typeof s === 'object' && (SHOT_TYPES as readonly string[]).includes((s as Shot).shot) && isValidShotPath((s as Shot).path, projectId, allowedFolders)) {
      out.push({ shot: (s as Shot).shot, path: (s as Shot).path });
    }
  }
  return out;
}
