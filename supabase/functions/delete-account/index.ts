// POST /functions/v1/delete-account   {}   (ACC-05 "Xóa tài khoản và toàn bộ dữ liệu")
// 1) removes the caller's files from Storage (SQL cannot delete storage objects), 2) calls delete_my_account(),
// which hands over / removes the household, deletes all rows and finally the auth user.
import { authenticate } from '../_shared/auth.ts';
import { errorResponse, HttpError, json, preflight } from '../_shared/http.ts';

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  try {
    if (req.method !== 'POST') throw new HttpError(405, 'method_not_allowed');
    const ctx = await authenticate(req);

    const { data: paths, error: pErr } = await ctx.admin.rpc('account_storage_paths', { p_user: ctx.userId });
    if (pErr) throw new HttpError(500, 'storage_listing_failed', pErr.message);
    const byBucket = new Map<string, Set<string>>();
    for (const r of (paths ?? []) as { bucket: string; path: string }[]) {
      if (!byBucket.has(r.bucket)) byBucket.set(r.bucket, new Set());
      byBucket.get(r.bucket)!.add(r.path);
    }
    // anything else under the user's own folder (e.g. replaced avatars)
    for (const bucket of ['avatars', 'checkins']) {
      const { data: files } = await ctx.admin.storage.from(bucket).list(ctx.userId, { limit: 1000 });
      for (const f of files ?? []) {
        if (f.id) {
          if (!byBucket.has(bucket)) byBucket.set(bucket, new Set());
          byBucket.get(bucket)!.add(`${ctx.userId}/${f.name}`);
        }
      }
    }
    let removed = 0;
    for (const [bucket, set] of byBucket) {
      const all = [...set];
      for (let i = 0; i < all.length; i += 100) {
        const { error } = await ctx.admin.storage.from(bucket).remove(all.slice(i, i + 100));
        if (error) throw new HttpError(500, 'storage_delete_failed', error.message);
        removed += Math.min(100, all.length - i);
      }
    }

    const { error } = await ctx.user.rpc('delete_my_account');
    if (error) throw new HttpError(500, 'delete_failed', error.message);
    return json({ deleted: true, files_removed: removed });
  } catch (e) {
    return errorResponse(e);
  }
});
