// Storage clean-up helpers for delete-account. Storage `list()` is not recursive: entries with `id === null` are
// "folders" (prefixes). Photos live in `{uid}/{projectId}/{uuid}.jpg`, so a top-level listing alone misses them.

export interface StorageEntry { name: string; id: string | null }

export interface StorageBucketLike {
  list(path: string, options?: { limit?: number; offset?: number }): Promise<{ data: StorageEntry[] | null; error: { message: string } | null }>;
}

const PAGE = 1000;
const MAX_DEPTH = 8;

/** Every object path (not folders) below [prefix], any depth, paging through large folders. */
export async function listRecursive(bucket: StorageBucketLike, prefix: string, pageSize = PAGE, depth = 0): Promise<string[]> {
  if (depth > MAX_DEPTH) return [];
  const out: string[] = [];
  for (let offset = 0;; offset += pageSize) {
    const { data, error } = await bucket.list(prefix, { limit: pageSize, offset });
    if (error) throw new Error(`storage_list_failed: ${error.message}`);
    const rows = data ?? [];
    for (const e of rows) {
      const path = `${prefix}/${e.name}`;
      if (e.id) out.push(path);
      else out.push(...await listRecursive(bucket, path, pageSize, depth + 1));
    }
    if (rows.length < pageSize) break;
  }
  return out;
}

export interface StorageLike { from(bucket: string): StorageBucketLike }

/**
 * Files to delete, per bucket: everything under `{uid}/` in `avatars` and `checkins` (including per-project
 * sub-folders) plus the paths the database knows about (e.g. photos stored under a household folder).
 */
export async function collectUserFiles(
  storage: StorageLike,
  userId: string,
  dbPaths: { bucket: string; path: string }[],
  buckets: string[] = ['avatars', 'checkins'],
): Promise<Map<string, Set<string>>> {
  const byBucket = new Map<string, Set<string>>();
  const add = (b: string, p: string) => {
    if (!byBucket.has(b)) byBucket.set(b, new Set());
    byBucket.get(b)!.add(p);
  };
  for (const r of dbPaths) add(r.bucket, r.path);
  for (const bucket of buckets) {
    for (const p of await listRecursive(storage.from(bucket), userId)) add(bucket, p);
  }
  return byBucket;
}
