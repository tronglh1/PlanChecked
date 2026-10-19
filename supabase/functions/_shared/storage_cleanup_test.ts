import assert from 'node:assert/strict';
import { collectUserFiles, listRecursive, type StorageBucketLike, type StorageEntry, type StorageLike } from './storage_cleanup.ts';

const U = 'u1';

/** In-memory bucket: a flat list of object paths, listed like Supabase Storage (one level, folders have id null). */
function fakeBucket(objects: string[], pageLimit = 1000): StorageBucketLike & { calls: string[] } {
  const calls: string[] = [];
  return {
    calls,
    list(path, opts) {
      calls.push(`${path}@${opts?.offset ?? 0}`);
      const prefix = path === '' ? '' : `${path}/`;
      const seen = new Map<string, StorageEntry>();
      for (const o of objects.filter((x) => x.startsWith(prefix))) {
        const rest = o.slice(prefix.length);
        const [first, ...tail] = rest.split('/');
        if (!seen.has(first)) seen.set(first, { name: first, id: tail.length ? null : `id-${o}` });
      }
      const all = [...seen.values()].sort((a, b) => a.name.localeCompare(b.name));
      const offset = opts?.offset ?? 0;
      return Promise.resolve({ data: all.slice(offset, offset + Math.min(opts?.limit ?? pageLimit, pageLimit)), error: null });
    },
  };
}

Deno.test('listRecursive finds files in per-project folders at any depth', async () => {
  const b = fakeBucket([
    `${U}/cover-old.jpg`,
    `${U}/p1/a.jpg`,
    `${U}/p1/b.jpg`,
    `${U}/p2/cover.jpg`,
    `${U}/p2/archive/2025/c.jpg`,
    `other/p1/x.jpg`,
    `${U}2/p1/y.jpg`, // a different user whose id merely starts with ours
  ]);
  const files = (await listRecursive(b, U)).sort();
  assert.deepEqual(files, [
    `${U}/cover-old.jpg`,
    `${U}/p1/a.jpg`,
    `${U}/p1/b.jpg`,
    `${U}/p2/archive/2025/c.jpg`,
    `${U}/p2/cover.jpg`,
  ]);
});

Deno.test('listRecursive pages through folders larger than one page', async () => {
  const objects = Array.from({ length: 7 }, (_, i) => `${U}/p1/f${i}.jpg`);
  const b = fakeBucket(objects);
  const files = await listRecursive(b, `${U}/p1`, 3);
  assert.equal(files.length, 7);
  assert.equal(new Set(files).size, 7);
  assert.deepEqual(b.calls, [`${U}/p1@0`, `${U}/p1@3`, `${U}/p1@6`]);
});

Deno.test('listRecursive surfaces storage errors instead of silently skipping files', async () => {
  const b: StorageBucketLike = { list: () => Promise.resolve({ data: null, error: { message: 'boom' } }) };
  await assert.rejects(listRecursive(b, U), /storage_list_failed: boom/);
});

Deno.test('collectUserFiles merges database paths with a recursive listing of avatars and checkins', async () => {
  const buckets: Record<string, StorageBucketLike> = {
    avatars: fakeBucket([`${U}/avatar.jpg`, `${U}/avatar-old.jpg`]),
    checkins: fakeBucket([`${U}/p1/a.jpg`, `${U}/p1/orphan-upload.jpg`, `${U}/p2/cover.jpg`, `h1/p9/shared.jpg`]),
  };
  const storage: StorageLike = { from: (b) => buckets[b] };
  const got = await collectUserFiles(storage, U, [
    { bucket: 'checkins', path: `${U}/p1/a.jpg` },
    { bucket: 'checkins', path: `h1/p9/shared.jpg` }, // household folder, only the DB knows it is ours
    { bucket: 'avatars', path: `${U}/avatar.jpg` },
  ]);
  assert.deepEqual([...got.get('avatars')!].sort(), [`${U}/avatar-old.jpg`, `${U}/avatar.jpg`]);
  assert.deepEqual([...got.get('checkins')!].sort(), ['h1/p9/shared.jpg', `${U}/p1/a.jpg`, `${U}/p1/orphan-upload.jpg`, `${U}/p2/cover.jpg`]);
});
