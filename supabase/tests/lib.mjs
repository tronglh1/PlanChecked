// Test helper: boots an in-memory Postgres (PGlite), applies the test prelude, every migration and the seed.
// PGlite is resolved from $PGLITE_ENTRY (absolute path to @electric-sql/pglite/dist/index.js) or from node_modules.
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
export const root = join(here, '..');

export async function loadPglite() {
  const entry = process.env.PGLITE_ENTRY;
  return entry ? import(pathToFileURL(entry).href) : import('@electric-sql/pglite');
}

export function sqlFiles(dir, re = /\.sql$/) {
  return readdirSync(join(root, dir)).filter((f) => re.test(f)).sort().map((f) => join(root, dir, f));
}

export async function bootDb({ seed = true } = {}) {
  const { PGlite } = await loadPglite();
  const db = new PGlite();
  await db.exec(readFileSync(join(here, 'prelude.sql'), 'utf8'));
  for (const f of sqlFiles('migrations')) {
    try {
      await db.exec(readFileSync(f, 'utf8'));
    } catch (e) {
      throw new Error(`migration failed: ${f}\n${e.message}`);
    }
  }
  if (seed) {
    for (const f of ['01_codes.sql', '02_text_templates.sql', '03_plants.sql']) {
      try {
        await db.exec(readFileSync(join(root, 'seed', f), 'utf8'));
      } catch (e) {
        throw new Error(`seed failed: ${f}\n${e.message}`);
      }
    }
  }
  return db;
}

export const U = {
  alice: '00000000-0000-4000-8000-00000000000a',
  bob: '00000000-0000-4000-8000-00000000000b',
  carol: '00000000-0000-4000-8000-00000000000c',
};

// Run fn(db) as an authenticated user (RLS enforced). Uses a transaction so SET LOCAL role is scoped.
export async function asUser(db, uid, sql, params = []) {
  await db.exec(`set role authenticated; select set_config('request.jwt.claim.sub', '${uid}', false);`);
  try {
    return await db.query(sql, params);
  } finally {
    await db.exec(`reset role; select set_config('request.jwt.claim.sub', '', false);`);
  }
}

export async function asService(db, sql, params = []) {
  await db.exec(`set role service_role; select set_config('request.jwt.claim.sub', '', false);`);
  try {
    return await db.query(sql, params);
  } finally {
    await db.exec('reset role;');
  }
}

export async function createUser(db, id, email, meta = {}) {
  await db.query('insert into auth.users(id, email, raw_user_meta_data) values ($1,$2,$3)', [id, email, JSON.stringify(meta)]);
}
