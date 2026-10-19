# Backend (Supabase) – Vườn Nhà

Everything lives in `supabase/`. Contract: `docs/spec-mvp.md` §4–§6. This page covers owner setup, the API surface the app uses, and every deviation from the spec.

```
supabase/
  config.toml
  migrations/   20261019000100_schema · 0200_functions · 0300_rls · 0400_storage_realtime_reference
  seed/         build.mjs (+ data/*.mjs) -> 01_codes.sql, 02_text_templates.sql, 03_plants.sql   (generated, committed)
  functions/    ai-plan, ai-checkin, invite, delete-account, _shared/ (+ *_test.ts)
  tests/        prelude.sql (test-only stubs), lib.mjs, db.test.mjs  (PGlite)
```

## 1. Owner setup (one time)

1. **Create the project** at supabase.com, region **Southeast Asia (Singapore)**. Save the DB password.
2. **Link and push** (CLI >= 2.x):
   ```bash
   supabase login
   supabase link --project-ref <ref>
   supabase db push --include-seed     # migrations + supabase/seed/*.sql (seed is idempotent, safe to repeat)
   ```
   If your CLI has no `--include-seed`, run the three files in `supabase/seed/` (in order) in the SQL editor or with `psql "$DB_URL" -f ...`. Seed must run once per environment: the plant/code/text tables are empty without it, and the app and AI functions depend on them.
3. **Secrets** (Edge Functions; the Anthropic key never reaches the app):
   ```bash
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
   # optional
   supabase secrets set INVITE_LINK_BASE=https://vuonnha.app/i   # deep-link base used in invite links
   supabase secrets set RESEND_API_KEY=re_... INVITE_FROM_EMAIL="Vườn Nhà <hello@yourdomain>"   # email invites
   supabase secrets set MODEL_PRICES_JSON='{"claude-haiku-5-5":{"in":1,"out":5,"cache_read":0.1}}' # cost metering overrides
   ```
   `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` are injected automatically.
4. **Deploy functions**:
   ```bash
   supabase functions deploy ai-plan ai-checkin invite delete-account --no-verify-jwt
   ```
   `--no-verify-jwt` (also set in `config.toml`) is intentional: each function verifies the user token itself via `auth.getUser()`, which works with asymmetric JWT signing keys.
5. **Auth providers** (Dashboard -> Authentication):
   - **URL configuration**: Site URL `https://vuonnha.app` (placeholder: your domain), Redirect URLs must include **`io.supabase.vuonnha://login-callback/`** (what the Flutter app uses; `com.planchecked.vuonnha://login-callback` is also whitelisted in `config.toml`).
   - **Google**: create an OAuth *Web* client (its id/secret go into Supabase, `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_SECRET` for local) **plus an Android OAuth client per signing key**: package `com.planchecked.vuonnha` with the **SHA-1 of the debug keystore, the release/upload keystore, and (if Play App Signing) the Play app-signing key** (Play Console -> App integrity). In Supabase add the Web client id and set "Skip nonce check" for native sign-in. The app signs in with the Web client id as `serverClientId`.
   - **Email OTP** ("Nhận mã đăng nhập"): Authentication -> Providers -> Email enabled, "Confirm email" optional; set the email template to show `{{ .Token }}` (6 digits). Supabase's built-in mailer is rate limited to a few mails/hour and only for team members: **configure custom SMTP** (Authentication -> SMTP Settings; e.g. Resend, SES, Brevo) with a verified sender domain before any real user tests.
6. **Realtime**: nothing to do; the migration adds `tasks`, `task_logs`, `task_occurrences`, `household_activity` to the `supabase_realtime` publication.
7. **Storage**: buckets `checkins` and `avatars` are created by the migration (private, 2 MB limit, jpeg/png/webp). Files are only reachable by signed URL.
8. **Reminder**: set Anthropic spend limits on the key; the per-user daily caps are in `app_config`.

Local dev: `supabase start` (Docker), `supabase db reset` (applies migrations + `[db.seed]`), `supabase functions serve --env-file supabase/.env`.

### Operations knobs (table `app_config`, editable in SQL editor)
| key | default | meaning |
|---|---|---|
| `ai_cap_plan` / `ai_cap_checkin` | 5 / 10 | AI calls per user per local day (retakes and AI failures are refunded) |
| `xp_daily_cap` | 150 | ordinary (`task_done`) XP per user per day |
| `xp_checkin_per_day` | 2 | check-in XP awards per user per day |
| `ai_escalate_below` | 0.6 | Haiku -> Sonnet when confidence is lower |
| `band_high` / `band_medium` | 0.75 / 0.5 | confidence bands (high / medium / low) |

After an agronomist reviews seed content: `update plants set data_status='verified'`, same for `text_templates`.

## 2. Tests (no Docker needed)

```bash
# SQL: every migration + seed + RLS/XP/quota/invite assertions in PGlite (in-memory Postgres)
cd supabase/tests && npm i && npm test
# Edge Function logic (validation, context, API client with mocked fetch, escalation)
cd supabase/functions && deno test _shared/ && deno check ai-plan/index.ts ai-checkin/index.ts invite/index.ts delete-account/index.ts
# regenerate seed SQL after editing supabase/seed/data/*.mjs
node supabase/seed/build.mjs
```
`supabase/tests/prelude.sql` stubs `auth`, `storage`, roles and default grants for PGlite only; never push it. Not covered: the live Anthropic call, Supabase Auth/Storage/Realtime themselves, the `pg_cron`-less check-in reminders.

## 3. API surface used by the app

Client: `supabase_flutter`. All tables are RLS-protected; the app uses plain `from(...).select/insert/update` where listed, otherwise RPC / Edge Function. Column names are the spec's; the three reserved words are quoted by PostgREST automatically: `"group"`, `"order"`, `"window"`.

### Tables the app reads / writes directly
| Table | App access |
|---|---|
| `users` | select/update own row (`display_name, avatar_path, lang, timezone, province_code, zone_code, experience, time_budget, prefer_organic, has_children, has_pets, quiet_start, quiet_end`). `xp_total`, `level`, `deleted_at` are server-owned (client changes are ignored). Row is created automatically on signup. |
| `member_profiles` (view) | household peers' `id, display_name, avatar_path, level, xp_total` |
| `notification_prefs` | upsert `(user_id, type)`; PK `(user_id, type)` |
| `push_tokens`, `consents`, `project_lessons`, `ai_feedback` | insert/select own |
| `plants`, `plant_stages`, `plant_problems`, `plant_default_tasks`, `task_codes`, `problem_codes`, `reason_codes`, `milestone_codes`, `text_templates`, `levels`, `badges_catalog`, `plan_templates`, `app_config` | read-only for any signed-in user |
| `projects` | insert (own), select (own + household-shared), update/delete (owner). `household_id` may only be set to a household where the caller has the Owner role |
| `plans`, `stages`, `tasks` | select (project members); insert/update/delete: project owner or household Owner role |
| `task_occurrences` | select only (created by `approve_plan` / `materialize_occurrences`) |
| `task_logs` | **insert only**: `{task_id, occurrence_date, action, skip_reason?, snooze_until?, note?, photo_path?, client_id?, acted_at?}`. `user_id` and `project_id` are filled by trigger. Unique `(user_id, client_id)` and one `done` per `(task_id, occurrence_date)`: treat Postgres `23505` as "already synced". `acted_at` = client action time; the server clamps it to `[now-7d, now]` |
| `checkins` | insert `{project_id, shots:[{shot,path}], tags:[...], note?}` (status forced to `pending`), select, delete own. No client update |
| `checkin_changes`, `milestones_reached`, `xp_events`, `user_badges`, `ai_usage`, `household_members`, `invites`, `household_activity` | select only. (`milestones_reached` also allows a manual claim `confirmed_by='user'` without check-in, which never yields XP) |
| `devices`, `sensor_readings` | IoT placeholder (own rows) |

Realtime (postgres_changes): `tasks`, `task_logs`, `task_occurrences`, `household_activity` (filter by `project_id` / `household_id`).

### RPCs (`supabase.rpc(name, params: {...})`)
| RPC | params -> returns |
|---|---|
| `search_plants` | `p_query text, p_group plant_group?, p_limit int=20` -> `plants[]`. Diacritic-free, token-AND match on `search_key`; empty query lists all |
| `vn_normalize` / `vn_search_key` | `p_text` -> text (same normalization as the plant `search_key`) |
| `fallback_plan` | `p_plant text, p_start start_stage` -> `{stages[], tasks[]}` (seed plan, usable offline-ish for preview) |
| `approve_plan` | `p_plan uuid` -> int (occurrences created). Marks plan approved, supersedes the old one, materializes 14 days |
| `materialize_occurrences` | `p_project uuid, p_from date?, p_to date?` -> int. Call on app open to roll the window forward (max 62 days) |
| `apply_checkin_changes` | `p_checkin uuid, p_accepted uuid[]` (ids of `checkin_changes` the user ticked) -> int applied. Unticked items stay discarded; rebuilds future occurrences |
| `consume_ai_quota` | `p_kind 'plan'\|'checkin'` -> `{used,cap,remaining}`; raises `ai_quota_exceeded` (SQLSTATE `P0429`). The Edge Functions call it; the app normally does not |
| `get_ai_quota` | -> `{plan:{used,cap}, checkin:{used,cap}}` for UI |
| `create_household` | `p_name` -> household row. Errors `already_in_household` |
| `create_invite` | `p_channel, p_target?, p_role` -> invite row (Owner only). Prefer the `invite` Edge Function |
| `accept_invite` | `p_code` -> `{ok:true, household_id, role}` or `{ok:false, error}` where error is `invite_invalid`, `invite_expired`, `already_in_household`, `too_many_attempts`. Code is case-insensitive, single use, 7 days; 10 failures/hour then locked |
| `revoke_invite` | `p_invite uuid` |
| `leave_household` | -> void. If the Owner leaves, ownership passes to the longest-standing member; the last member leaving deletes the household. The leaver's shared projects become private |
| `remove_member` | `p_user uuid` (Owner only) |
| `my_streak` | -> int (consecutive local days with a done task, counting back from today or yesterday) |
| `delete_my_account` | -> void; hands over/removes household, deletes all user data and the auth user. **Call the `delete-account` Edge Function instead** so files are removed from Storage first |

Error mapping: Postgres exceptions surface as `PostgrestException.message` with the strings above (`future_occurrence`, `not_household_owner`, `not_allowed`, `ai_quota_exceeded`, ...).

### Edge Functions (`supabase.functions.invoke(name, body: {...})`, user JWT sent automatically)

**`ai-plan`** request `{ "project_id": uuid, "regenerate"?: bool, "plant_group"?: "rau_qua"|"cay_canh" }` (the project row must already exist; for a plant not in the DB create the project with `plant_id = null`, `plant_name_custom = "<text>"` and pass `plant_group`).
Response 200:
```json
{ "plan_id": "uuid", "source": "template|ai|fallback", "confidence": 0.86,
  "template_key": "tomato_cherry|VN_S|rainy|seedling|balcony|sun3", "model": "claude-haiku-5-5",
  "from_cache": false, "fallback_reason": null, "new_plant": false,
  "stages": [{"code":"S1","day_from":1,"day_to":7,"milestone":"SPROUT","name_vi":"...","name_en":"..."}],
  "tasks":  [{"task":"T_WATER","stage":"S2","every_d":2,"window":"morning","offset_d":0,"why":"R_HOT_SEASON"}] }
```
`fallback_reason` is `quota_exceeded | ai_error | invalid_output | null`; `source:"fallback"` means the seed plan was used (never an error). The plan is a **draft** (`plans.status='draft'`, `tasks` rows exist); show it for review, let the user edit `tasks`, then call `approve_plan`. If a draft already exists it is returned (`from_cache:true`) unless `regenerate:true`. `every_d`: 0 = once, 1 = daily. Render texts from `text_templates` by `task`/`why` codes. Errors: 401 `unauthorized`, 400 `invalid_project_id`, 403 `not_project_owner`, 404 `project_not_found`.
Order inside: owner check -> template lookup by key (no AI, no quota) -> `consume_ai_quota('plan')` -> Haiku (Sonnet first if plant unknown; Sonnet again if invalid or confidence < threshold) -> validation (known codes only, params in range, no dose-like text, a `T_CHECKIN` in every stage) -> save template (confidence >= 0.5) and draft plan. Any failure falls back to `fallback_plan` and refunds the quota.

**`ai-checkin`** request `{ "checkin_id": uuid }`. Flow for the app: resize to 768 px JPEG q75 -> upload to bucket `checkins` at `{user_id or household_id}/{project_id}/{uuid}.jpg` -> insert `checkins` row with `shots:[{"shot":"whole_plant","path":"..."}]`, `tags`, `note` (<= 200 chars) -> invoke.
Responses 200 (`status`):
```json
{ "status": "ok", "checkin_id": "uuid", "model": "claude-haiku-5-5", "escalated": false,
  "stage_est": {"code":"S3_late","confidence":0.82}, "health": {"value":"good","confidence":0.8},
  "issues": [{"code":"P_CALCIUM_LOW","confidence":0.58,"severity":1,"actions":[{"task":"T_EGGSHELL_ADD"}]}],
  "milestone_seen": {"code":"HEIGHT_40","confidence":0.9}, "milestone": {"code":"HEIGHT_40","confidence":0.9,"new":true},
  "delta": [{"op":"add","task":"T_EGGSHELL_ADD","stage":"S3","every_d":null,"window":null,"why":null}],
  "changes": [{"id":"uuid","change_kind":"add","payload":{...}}],
  "reason_codes": ["R_HOT_SEASON"], "confidence_band": "medium", "low_confidence": false,
  "xp": {"xp_total": 1280, "level": 4} }
{ "status": "retake", "reason": "BLUR|DARK|TOO_FAR|NOT_PLANT", "hint_code": "H_RETAKE_LIGHT", "checkin_id": "uuid" }
{ "status": "skipped_recent", "previous_checkin_id": "uuid", "checkin_id": "uuid" }      // same project analyzed < 24 h ago, no new tag
{ "status": "already_processed", "checkin_status": "analyzed", "result": {...} }
```
Errors: 429 `ai_quota_exceeded` (body has `quota`), 400 `no_valid_shots | image_not_found | image_too_large | image_not_jpeg`, 502 `{status:"error", code:"AI_UNAVAILABLE"}` (quota refunded, no delta, plan unchanged), 403 `not_checkin_author`, 404.
The user ticks `changes[]`; the app calls `apply_checkin_changes(checkin_id, accepted_ids)`. `changes[].payload.op` is `add | remove | change_freq | shift`. Retakes do not use quota and earn no XP. Check-in XP (+30) and milestone XP (+100) are awarded by DB triggers once the function marks the check-in `analyzed`; the app only displays `xp`. `low_confidence:true` (band `low`) -> suggest a local agricultural store (CHK-08). Hint/reason texts: `text_templates` kind `hint`.

**`invite`** request `{ "channel": "link|code|email|phone", "target"?: "a@b.com", "role"?: "member|owner" }` (caller must be household Owner) -> `{ "invite": {id, code:"VUON-1234", expires_at, role, channel}, "link": "https://vuonnha.app/i/VUON-1234", "email_sent": false, "email_error"?: "email_not_configured|provider_NNN", "sms_error"?: "sms_not_supported" }`. Email is only sent when `RESEND_API_KEY` + `INVITE_FROM_EMAIL` are set; otherwise share `code`/`link` through the OS share sheet. Phone is never sent by the server. The receiving user calls `accept_invite(code)`; the app must handle `link` deep links (`/i/<code>`).

**`delete-account`** request `{}` -> `{ "deleted": true, "files_removed": n }`. Removes the user's files in `checkins`/`avatars`, then calls `delete_my_account()`.

### Storage
- `checkins` (private): `{user_id or household_id}/{project_id}/{uuid}.jpg` (only `.jpg`). Read: any member of the project (owner or shared household). Insert: caller must have access to the project and the first folder must be their user id or the project's household id. Delete: uploader. Project covers use the same bucket (`{user_id}/{project_id}/cover.jpg`).
- `avatars` (private): `{user_id}/avatar.jpg`. Read: self and household peers; write: self. Use signed URLs.

## 4. Deviations from, and additions to, spec §4

Everything in spec §4.2 exists with the same names, except as listed.

**Representation choices**
- `plants.id` is a **text slug** (`tomato_cherry`, `basil`, `kangkong`...), matching the AI doc's `plant_id` and the template key; `projects.plant_id` is text. Other ids are uuids.
- Enums are Postgres enums named as in §4.1 except: `role` -> `member_role`; `condition_tag` values `LEAF_YELLOW|WILT|PESTS|SPOTS`; `start_stage` `seed|seedling|mature`; `difficulty` `easy|medium|hard`; `change_kind` `add|remove|shift|change_freq` (the frequency-change op is `change_freq`, as in the §5.2 output); `time_budget` is text with values `<10p`, `10-30p` (ASCII hyphen, as in the §5.1 input), `>30p`; `pot_type` and `health` are free text (health values used: `good|fair|poor`); `sun_level` is int 1..4. Suggested UI mapping for the three mockup buckets: "<3h" -> 1, "3-6h" -> 2, ">6h" -> 3, 4 reserved for open rooftops (gap 14 is still open for product).
- Code lists `task_codes`, `problem_codes` are tables; **added** `reason_codes (code)` and `milestone_codes (code, sort_order)` so codes can be validated. `problem_codes.symptoms` = condition tags, `causes` = reason codes, `safe_actions` = task codes (all `text[]`), `severity` 1..3 (mild / moderate / severe; gap 36 decided).
- `text_templates.kind` also has `tag` (condition-tag labels) and `hint` (retake hints); `field` is `name|steps|why|safety` as spec. Seed mapping: title=`name`, instructions=`steps` (newline separated), reason=`why`. Condition tags and `H_RETAKE_*` hints are texts of kind `tag`/`hint`.
- `plan_templates` stores the plan body as `body jsonb` (`{stages, tasks}`, same shape as the AI output) instead of separate `template_stages/template_tasks` tables (final spec dropped them), plus `confidence`.
- `ai_usage` primary key is `(user_id, day, kind)`; `model` = last model used, tokens/cost accumulate.
- Reserved-word columns kept verbatim and always quoted: `plants."group"`, `task_codes."group"`, `plant_stages."order"`, `tasks."window"`, `task_occurrences."window"`.
- `users.zone_code` is `VN_N|VN_C|VN_S` (default `VN_S`); `province_code` is a free text slug (e.g. `tp-hcm`) used by the app; the server only uses `zone_code`. Season: south `rainy` (May-Oct) / `dry`, north & centre `hot` (May-Oct) / `cool`.

**Added columns / tables**
- `users`: `has_children`, `has_pets` (needed for the `household` block of the AI input and toxic-plant rules), `updated_at`.
- `projects`: `plant_name_custom` (plant not in DB; `plant_id` may then be null until AI creates it), `updated_at`. `households.updated_at` etc: `updated_at` exists on every mutable table, with triggers.
- `plants`: `search_key` (diacritic-free + aliases, built with `vn_search_key`), `hidden` (two generic fallback plants `generic_edible`, `generic_ornamental` are never listed). `plant_stages.phase` (`seed|seedling|mature`; used to cut a plan when the project starts at `seedling`/`mature`).
- `plant_problems (plant_id, problem_code, rank)` and `plant_default_tasks (plant_id, stage_code, task_code, window, every_d, offset_d, reason_code)`: the per-plant default plan / fallback.
- `tasks`: `reason_code`, `day_offset` (first run = stage `day_from` + offset). For `frequency='fixed_date'`, `interval_days` holds the day of the month. `task_occurrences`: `project_id`, `assignee_id`. `task_logs`: `project_id`, `acted_at`.
- `stages`: `name_en`. `plans`: `model`.
- New tables: `levels`, `app_config`, `household_activity` (feed HSH-06, in the Realtime publication), `invite_attempts`, `sensor_readings`; `devices` also has `project_id`.

**Business rules decided where the spec is open (§7 gaps)** – all adjustable in SQL/`app_config`:
- Task XP +10 only if logged on the occurrence day in the user's timezone **and** the task is truly due that day; late logs earn 0 (gap 24). One award per task per day (undo/redo cannot farm). Logging a future occurrence raises `future_occurrence`.
- Daily cap 150 applies to task XP only. Check-in XP (+30) sits outside the cap but is limited to 1 per project/day and 2 per user/day; retakes earn nothing (gaps 34, 54). Milestone +100 only through a milestone row attached to an analyzed check-in of the same project (AI-confirmed, confidence >= 0.75). Project completed: +200, once, only if the project has a photo-confirmed milestone (gap 53 – amount is my proposal).
- Levels (`levels` table): 1 Người mới 0, 2 Người ươm mầm 250, 3 Người yêu cây 700, 4 Người chăm chỉ 1250, 5 Thợ vườn 1500, 6 Nhà vườn 3000 (only 1, 4, 5, 6 names and 1250/1500 come from the sources; the rest is proposed – gap 51).
- Badges: 16 rows in `badges_catalog` with machine-readable `criteria` (the 8 named in the mockup plus 8 proposed). Milestone badges need a photo-confirmed milestone. Streak = consecutive local days with at least one done task (gap 55).
- Daily AI caps: plan 5, check-in 10 (gap 42). Confidence bands high >= 0.75, medium >= 0.5 else low (gap 31); Sonnet escalation below 0.6 or for plants not in the DB.
- Household: Owner can invite, assign, edit shared plans/tasks, share projects; Member can view, Done/Skip/Snooze, check in, and leave. Members cannot share projects (gap 62) or invite (gap 57). Owner role can be granted in an invite (gap 58). Owner leaving passes ownership to the longest-standing member (gap 59); removing a member is Owner-only (gap 60). Invite code `VUON-` + 4 digits, single use, 7 days.
- Check-in AI failure (gap 38): HTTP 502 `AI_UNAVAILABLE`, nothing applied, quota refunded.
- Seed content (plants, 34 task codes, 20 problem codes, 536 texts VN/EN) is authored, **not expert-reviewed**: rows are `data_status='ai_unverified'` and toxic flags should be checked before launch. No doses anywhere; organic first; labels referenced for any product.

**Not built (out of scope / needs product input)**: FCM sending and `pg_cron` reminders (no `push_tokens` consumer yet), email/SMS beyond the optional Resend email, leaderboard, away-member rotation skipping (`away_until` exists), IoT ingest, photo-retention policy (gap 49).
