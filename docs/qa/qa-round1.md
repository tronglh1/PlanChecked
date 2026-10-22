# QA round 1: Vườn Nhà (branch `mvp`)

Scope: HEAD of `mvp` (working tree clean at start). No source files edited, no commits, no pushes. Byproducts: `supabase/tests/package-lock.json` (untracked, from `npm i`, left in place), scratch files under `/tmp/claude-0/` (deno install, probe scripts).

Summary: the test suites are green, but the Dart-to-Supabase boundary has one critical and several high-severity runtime breaks that no suite catches. Two of them were reproduced by replaying the app's exact SQL as the `authenticated` role.

## 1. Test results

| Suite | Command | Result |
|---|---|---|
| Flutter analyze | `flutter analyze` (app/) | No issues found, exit 0 |
| Flutter tests | `flutter test` (app/) | 217 passed, 0 failed |
| SQL (PGlite, 17 subtests) | `npm i && npm test` (supabase/tests/) | 17 run, 17 pass, 0 fail |
| Edge Function unit tests | `deno test _shared/` (supabase/functions/) | 27 passed, 0 failed |
| Edge Function type check | `deno check ai-plan/index.ts ai-checkin/index.ts invite/index.ts delete-account/index.ts` | exit 0 |

Environment notes:
- `deno` was not on PATH and docs/backend.md names no npm package for it. I used deno 2.9.6 from the npm `deno` package, installed in a scratch directory (not in the repo, not global). The repo has a `deno.lock`, but no deno version is pinned, so the owner's version may differ.
- `flutter` warned that it is running as root. No effect on results.
- Green suites do not exercise the Dart-to-Supabase boundary (see section 2 and section 5.1).
- Replay method: I ran the app's write and read statements as the `authenticated` role in the same PGlite build the SQL suite uses (scratch script `/tmp/claude-0/qa-probe/probe.mjs`). Items marked REPRODUCED come from that replay. PostgREST is emulated as the SQL it generates (upsert = `INSERT ... ON CONFLICT DO UPDATE`).

## 2. Contract mismatches (ranked by severity)

### C1. CRITICAL: profile save always fails, so onboarding cannot complete (REPRODUCED)
- App: `app/lib/features/profile/data/profile_repository.dart:41` `_client.from('users').upsert(profile.toRow())`. Called from `profile_setup_screen.dart:120-135` via `profile_providers.dart:28`.
- Backend: `supabase/migrations/20261019000300_rls.sql:157` `revoke insert on public.users from anon, authenticated;`. There is also no INSERT policy on `users` (supabase/migrations/20261019000300_rls.sql:28-31 has only select and update).
- Why it breaks: PostgREST upsert is `INSERT ... ON CONFLICT (id) DO UPDATE`. That needs INSERT privilege and an INSERT policy even when the row already exists. Replay result: `permission denied for table users`.
- Effect: the `handle_new_user` trigger creates a `users` row with no province, so the profile gate keeps every new user on the setup screen, and Save fails each time.
- Fix direction: use `update(...).eq('id', uid)` at `profile_repository.dart:41` (the row always exists via the trigger). No migration needed.

### C2. HIGH: a household Member cannot create a project (REPRODUCED)
- App: `project_repository.dart:121-129` `_householdId()` returns the household for any member, and `:136` sends it as `household_id` in the insert at `:134-149`.
- Backend: `supabase/migrations/20261019000300_rls.sql:59-60` `projects_insert` requires `is_household_owner(household_id)` whenever `household_id` is not null.
- Effect: every Member's insert is rejected with `new row violates row-level security policy for table "projects"`. Owners are fine. Replay: Member with household is refused; Member with `household_id` null succeeds.
- The docs say Members cannot share projects (backend.md, gap 62).
- Fix direction: set `household_id` only when the caller's role is owner, otherwise leave it null.

### C3. HIGH: `day_offset` is ignored by the client schedule, so the server's due day differs (code-verified, data counted)
- Server: `supabase/migrations/20261019000200_functions.sql:129` in `task_due_on`: `v_first := v_from + t.day_offset;`. `create_draft_plan` writes `offset_d` into `tasks.day_offset` at `:683`. `task_logs_after_insert` (`:340`) uses `task_due_on` to decide on-time XP.
- Client: nothing in `app/lib` reads `day_offset`. `Task` (`plan/domain/models.dart:119-216`) has no such field, and `Task.fromJson` drops it. `TaskScheduler` starts each task at `stage.dayFrom` (`plan/domain/task_scheduler.dart:62-68`). The calendar uses it (`plan_calendar_screen.dart:105`).
- Data: 412 of 605 seeded `plant_default_tasks` rows have `offset_d > 0` (counted in PGlite).
- Effect: a task the app shows as due on day 1 has its server due day at day 1 + offset. Logging on the day the app shows earns no XP (`task_due_on` is false). `task_occurrences` and the project list's "today" count fall on different days than the screens. Silent: no error.
- Fix direction: carry `day_offset` through the Dart `Task` model and `TaskScheduler`, or stop the server adding it. Add a shared golden test.

### C4. HIGH: `fixed_date` means different things on client and server (code-verified)
- App: `plan/presentation/task_edit_sheet.dart:113` sets `n` from the day field for `fixedDate` and sends it as `interval_days` at `:129`. `plan/domain/task_scheduler.dart:87-95` treats `intervalDays` as a project day number. `plan/presentation/plan_labels.dart:30` labels it "Ngày N".
- Backend: `supabase/migrations/20261019000200_functions.sql:135` `when 'fixed_date' then extract(day from p_date)::int = coalesce(t.interval_days, 1)`, which is a calendar day of month. backend.md section 4 says the same.
- The explicit calendar date is never persisted: `plan_repository.dart:164-179` (insert) and `:184-195` (update) do not send `fixed_date`, and `tasks` has no such column.
- Effect: "Ngày 20" appears on project day 20 in the app, but server occurrences and on-time XP use the 20th of each calendar month.
- Fix direction: pick one meaning, store it (day-of-month in `interval_days`, or a real `fixed_date` column), and make the client scheduler match.

### C5. HIGH: account deletion skips Storage cleanup (code-verified)
- App: `features/auth/data/auth_repository.dart:61-62` calls `rpc('delete_my_account')` directly. It is reached from `settings/presentation/settings_screen.dart:77`.
- Backend: `supabase/functions/delete-account/index.ts:14-41` is the path that removes checkin photos and avatars first. The comment on `delete_my_account` (`supabase/migrations/20261019000200_functions.sql` around line 787) says the same. Once the RPC deletes `auth.users`, the storage paths can no longer be looked up from the DB.
- Effect: photos and avatars of deleted accounts stay in the private buckets permanently. This is a privacy and deletion-promise risk for the "delete all data" flow (ACC-05).
- Fix direction: call `functions.invoke('delete-account')` from `auth_repository.dart` instead of the RPC.

### C6. MEDIUM: household members' names are never shown from `users` (REPRODUCED)
- App: `today/data/task_repository.dart:120-123` reads other members' `display_name` from `users`.
- Backend: `supabase/migrations/20261019000300_rls.sql:28-29` `users_select_self` only. Replay: a member reading a peer from `users` gets 0 rows; from `member_profiles` (`supabase/migrations/20261019000300_rls.sql:35-39`, built for this) gets 1 row.
- Effect: other members' names are missing on Today. The code keeps a partial map, so nothing errors.
- Fix direction: query `member_profiles`.

### C7. MEDIUM: the English locale shows Vietnamese stage names (code-verified)
- App: `plan/domain/models.dart:96-105` `Stage.fromJson` reads `name` only. The UI uses `stage.name` at `projects/presentation/project_detail_screen.dart:349-350`, `project_list_screen.dart:174-175`, `plan/presentation/plan_review_screen.dart:416` and `today/presentation/task_detail_screen.dart:90`.
- Backend: `create_draft_plan` (`supabase/migrations/20261019000200_functions.sql:669-670`) sets `name = name_vi` and stores `name_en`, which nothing reads.
- Fix direction: read `name_en` and choose by locale.

### C8. MEDIUM: consents are never written (docs-declared write not implemented)
- backend.md section 3 lists `consents` as an app insert/select table. No Dart code writes it (grep). The RLS policy exists (`supabase/migrations/20261019000300_rls.sql:131-132`).
- Risk: no stored record of terms, privacy or ND13 acceptance.

### C9. LOW: `plans.sources` is read but the column does not exist
- `plan_repository.dart:116` reads `pick['sources']`. The `plans` table (`supabase/migrations/20261019000100_schema.sql`) has no such column. The result is always an empty list. No crash.

### C10. LOW: push platform value can violate the CHECK on desktop builds
- `today/data/push_service.dart:157-162` falls back to `defaultTargetPlatform.name` (`linux`, `macos`, `windows`, ...). `push_tokens.platform` only accepts `android|ios|web` (`supabase/migrations/20261019000100_schema.sql`, `push_tokens`). Mobile targets are fine.

### C11. LOW: `snooze_until` is sent as a date
- `today/data/task_repository.dart:141-143` sends `yyyy-MM-dd` into a `timestamptz` column (`task_logs.snooze_until`). Postgres reads that as 00:00 UTC, which is 07:00 in Vietnam. It only matters if something reads `snooze_until` as a time of day. Nothing does today.

### C12. LOW: cover upload uses upsert without an UPDATE policy on the bucket
- `projects/data/project_repository.dart:163-167` uses `upsert: true` on `checkins`. The storage policies on `checkins` cover select, insert and delete only (`supabase/migrations/20261019000400_storage_realtime_reference.sql:22-27`). A retry on the same project cover would fail. The error is caught and the cover is optional, so the impact is small.

Checked and matching (no mismatch found):
- Every `.from(...)` table name and column used in select, insert, update and upsert, across all repositories.
- Embedded relations: `projects` to `plants`, `plans` and `tasks`; `plans` to `stages`; `checkins`; `task_logs` to `tasks` in the Edge Functions.
- RPC names and parameters: `approve_plan(p_plan)`, `materialize_occurrences(p_project)`, `delete_my_account()`.
- `ai-plan` request keys (`project_id`, `regenerate`, `plant_group`) and response keys (`plan_id`, `source`, `fallback_reason`).
- Enum strings in `plan/domain/enums.dart`, `projects/domain/project.dart`, `plan/domain/models.dart`, `settings/domain/notification_settings.dart` and `profile/domain/user_profile.dart`, against the SQL enums.
- `onConflict` keys: `notification_prefs` on `user_id,type`; `push_tokens` on `token`.
- Storage paths (`checkins/{uid}/{pid}/cover.jpg`, `avatars/{uid}/avatar.jpg`) and Realtime tables (`tasks`, `task_logs`).
- Edge Function internal RPC and table references: `create_draft_plan`, `ai_usage_record`, `create_invite`, `fallback_plan`, `checkin_changes`, `milestones_reached`, `task_logs`, storage `checkins`.

## 3. RLS gaps

| Table / object | Operation (role) | Policy | Status |
|---|---|---|---|
| users | upsert = insert (self), profile save | none. INSERT revoked (supabase/migrations/20261019000300_rls.sql:157), no insert policy | BROKEN, C1 |
| users | update lang and profile (self) | `users_update_self` (supabase/migrations/20261019000300_rls.sql:30-31) | OK |
| users | read other members' display_name | `users_select_self` only (supabase/migrations/20261019000300_rls.sql:28-29) | GAP, C6 |
| projects | insert with household_id (Member) | `projects_insert` (supabase/migrations/20261019000300_rls.sql:59-60) | BROKEN, C2 |
| projects | insert, private or owner-with-household (owner) | `projects_insert` | OK |
| projects | update cover_path (owner) | `projects_update` (supabase/migrations/20261019000300_rls.sql:61-63) | OK |
| tasks | insert, update, archive (owner or household Owner) | `tasks_write` (supabase/migrations/20261019000300_rls.sql:80-81) | OK. Members blocked, as designed |
| task_logs | insert done, skip, snooze (member with access, assignee rule) | `task_logs_insert` (supabase/migrations/20261019000300_rls.sql:89-96) | OK. No update or delete, by design |
| notification_prefs | upsert (self) | `notification_prefs_all` (supabase/migrations/20261019000300_rls.sql:127-128) | OK |
| push_tokens | upsert (self) | `push_tokens_all` (supabase/migrations/20261019000300_rls.sql:129-130) | OK. A token already owned by another user is refused, as documented |
| storage checkins | cover insert (self) | `checkins_objects_insert` (20261019000400_storage_realtime_reference.sql:24-25) | OK. Upsert retry lacks UPDATE policy, C12 |
| storage avatars | insert and upsert (self) | `avatars_objects_insert` and `_update` (20261019000400_storage_realtime_reference.sql:32-35) | OK |
| consents | none written by app | `consents_insert` exists (supabase/migrations/20261019000300_rls.sql:132) | Unused, C8 |
| checkins | none written by app yet | `checkins_insert` requires status `pending` and `ai_result` null (supabase/migrations/20261019000300_rls.sql:100-102) | Ready when check-in is wired |
| plans, stages, task_occurrences, households, household_members, invites, xp_events, ai_usage | no client write; app calls only `approve_plan`, `materialize_occurrences`, `delete_my_account` | SECURITY DEFINER functions with their own checks | OK |

Storage delete by owner is allowed (20261019000400_storage_realtime_reference.sql:26-27), but the app never deletes objects. That is why C5 matters.

## 4. l10n gaps

- `app/l10n/app_vi.arb` and `app_en.arb` each have 336 keys, with identical key sets. No orphan `@key` metadata, placeholders are consistent in both files, and the generated `app_localizations_{vi,en}.dart` cover every key. No key-parity gap.
- One value problem: `projectDetailTabPlan` is "Plan" in `app_vi.arb:300`, an English word in the Vietnamese UI. It needs a Vietnamese label. `app_en.arb:300` is fine.
- Other identical vi/en values are intentional: `appName`, `langVi`, `langEn`, `loginEmailLabel`, and format strings such as `{plant} – {month}/{year}`.
- Not checked: hard-coded user-facing strings in widgets outside `AppLocalizations`.

## 5. Other risks

1. No contract tests cross the Dart-to-SQL boundary. All suites are green while C1 and C2 are real and reproducible. A test that runs each repository's SQL as `authenticated` would catch them; the probe script is a starting point.
2. Scheduling is duplicated: `TaskScheduler` in Dart and `task_due_on` in SQL. C3 and C4 are drift between the two. Pick one source of truth, or have the server return occurrences.
3. Several server paths have no client caller. `ai-checkin` has no invoke and no `checkins` insert (`project_detail_screen.dart:530` says check-in "lands in a later milestone"). `invite`, `create_household` and `accept_invite` have no UI. `delete-account` is not called (C5). These paths are untested from the client.
4. The Edge Function tests cover pure logic only. The DB calls in `ai-plan`, `ai-checkin`, `invite` and `delete-account` are not run by any test, and `deno check` only type-checks them. I verified their column and RPC references by reading the code.
5. The PGlite harness stubs `auth` and `storage`. Storage policies were checked by reading, not by running. The probe uses the harness's `auth.uid()`.
6. Repo hygiene: `supabase/tests/package-lock.json` is untracked, created by `npm i`, and left in place. `node_modules` is ignored.
7. Not tested: live Anthropic calls, Google and email sign-in, Realtime delivery, push delivery, and real PostgREST behavior (emulated in the replay).

## Resolution (round 1 fixes)

- **C1** Resolution: `SupabaseProfileRepository.save` now does `update(row).eq('id', uid).select('id')` and throws if zero rows come back (so the UI shows the save error instead of a false success). PGlite test: own-row UPDATE works, INSERT is permission denied.
- **C2** Resolution: decided per spec §6.6 that Members may create projects in their own household. New migration `20261019000500_qa1_fixes.sql` relaxes `projects_insert` and the `projects_update` check to `is_household_member`. PGlite test covers Member insert, cover_path update, outsider rejected, spoofed owner rejected. docs/backend.md updated.
- **C3** Resolution: Dart `Task` carries `dayOffset`; `TaskScheduler.expand` starts at `stage.dayFrom + dayOffset` like SQL `task_due_on`. Mirrored cases in `task_scheduler_test.dart` and a SQL test of `task_due_on` with offsets.
- **C4** Resolution: SQL semantics chosen: `interval_days` is the day of the month. Dart scheduler matches, the unpersistable `fixedDate` was removed from `Task`, the edit sheet clamps to 31, labels read "Ngày N hằng tháng" / "Day N of the month". Documented in docs/backend.md.
- **C5** Resolution: `AuthRepository.deleteMyAccount` invokes the `delete-account` Edge Function (Settings already goes through the repository, so the settings screen is untouched).
- **C6** Resolution: member names are read from the `member_profiles` view.
- **C7** Resolution: `Stage` parses `name_en`; new `Stage.label(lang)` is used in project detail, project list, plan review and task detail. Unit test added.
- **C8** Resolution: after a successful profile save, `recordConsents('2026-10')` inserts `terms`, `privacy`, `nd13` rows once per version (best effort, never blocks onboarding).
- **C9** Resolution: the non-existent `plans.sources` read was removed; sources stay empty.
- **C10** Resolution: push platform is `android`, `ios`, otherwise `web`, so desktop builds cannot violate the CHECK.
- **C11** Resolution: kept as is on purpose. The app reads `snooze_until` back as a calendar date (`parseIsoDate` ignores the time), so sending a local-midnight timestamp would round-trip to the previous day in UTC+7. A date at 00:00 UTC is lossless for that use.
- **C12** Resolution: migration adds `checkins_objects_update` storage policy (owner, valid path, .jpg) so cover upsert retries work.
- **l10n** Resolution: `projectDetailTabPlan` in `app_vi.arb` is now "Kế hoạch"; generated localizations regenerated.
- **Section 5** Resolution: added SQL-level contract tests (Member insert, profile update/insert, `task_due_on` cases). Repository-level Dart-to-PostgREST tests remain future work.
