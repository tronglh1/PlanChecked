// JWT verification + Supabase clients. Functions are deployed with verify_jwt = false (see config.toml) because
// we verify the user token ourselves, which also works with asymmetric JWT signing keys.
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { HttpError } from './http.ts';

export interface AuthContext {
  userId: string;
  jwt: string;
  /** Acts as the user: RLS applies, auth.uid() works inside RPCs. */
  user: SupabaseClient;
  /** Service role: bypasses RLS. Only use after the caller has been verified and authorised. */
  admin: SupabaseClient;
}

function env(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new HttpError(500, 'server_misconfigured', `missing env ${name}`);
  return v;
}

export function adminClient(): SupabaseClient {
  return createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function authenticate(req: Request): Promise<AuthContext> {
  const header = req.headers.get('Authorization') ?? '';
  const m = /^Bearer\s+(.+)$/i.exec(header);
  if (!m) throw new HttpError(401, 'unauthorized');
  const jwt = m[1];
  const user = createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await user.auth.getUser(jwt);
  if (error || !data.user) throw new HttpError(401, 'unauthorized');
  return { userId: data.user.id, jwt, user, admin: adminClient() };
}
