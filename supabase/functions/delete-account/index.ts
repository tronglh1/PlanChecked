// POST /functions/v1/delete-account   {}   (ACC-05 "Xóa tài khoản và toàn bộ dữ liệu")
// 1) removes the caller's files from Storage (SQL cannot delete storage objects), 2) calls delete_my_account(),
// which hands over / removes the household, deletes all rows and finally the auth user.
import { authenticate } from '../_shared/auth.ts';
import { errorResponse, HttpError, json, preflight } from '../_shared/http.ts';
import { collectUserFiles } from '../_shared/storage_cleanup.ts';

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  try {
    if (req.method !== 'POST') throw new HttpError(405, 'method_not_allowed');
    const ctx = await authenticate(req);

    const { data: paths, error: pErr } = await ctx.admin.rpc('account_storage_paths', { p_user: ctx.userId });
    if (pErr) throw new HttpError(500, 'storage_listing_failed', pErr.message);
    // Paths the database references + everything under `{uid}/` in both buckets, recursively (per-project
    // folders, orphaned uploads whose `checkins` insert failed, replaced avatars).
    let byBucket: Map<string, Set<string>>;
    try {
      byBucket = await collectUserFiles(ctx.admin.storage, ctx.userId, (paths ?? []) as { bucket: string; path: string }[]);
    } catch (e) {
      throw new HttpError(500, 'storage_listing_failed', (e as Error).message);
    }
    let removed = 0;
    for (const [bucket, set] of byBucket) {
      const all = [...set];
      for (let i = 0; i < all.length; i += 100) {
        const chunk = all.slice(i, i + 100);
        const { error } = await ctx.admin.storage.from(bucket).remove(chunk);
        if (error) throw new HttpError(500, 'storage_delete_failed', error.message);
        removed += chunk.length;
      }
    }

    const { error } = await ctx.user.rpc('delete_my_account');
    if (error) throw new HttpError(500, 'delete_failed', error.message);
    return json({ deleted: true, files_removed: removed });
  } catch (e) {
    return errorResponse(e);
  }
});
