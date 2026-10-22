# QA round 2: Vườn Nhà (branch `mvp`)

Scope: working tree of `mvp` at QA start (round 1 fixes present). No source files edited, no commits, no pushes. The only repo write is this file. Byproduct from earlier: `supabase/tests/package-lock.json` (untracked, from `npm i`). Scratch deno binary lives in `/tmp/claude-0/deno-scratch` (outside the repo, reused from round 1).

Summary: all suites are green and the round 1 fixes are still in place. The main new finding is a navigation dead end: the milestone celebration screen (GAM-03) is built and routed but nothing in the app navigates to it, so the "new milestone" branch of journey (d) never happens. Two MVP notification toggles do nothing, and the household invite-link flow loses the code across a sign-in.

## 1. Test results

| Suite | Command | Result |
|---|---|---|
| Flutter analyze | `flutter analyze` (app/) | No issues found (exit 0) |
| Flutter tests | `flutter test` (app/) | 297 passed, 0 failed (round 1: 217) |
| SQL (PGlite) | `npm i && npm test` (supabase/tests/) | 19 run, 19 pass, 0 fail (round 1: 17 subtests) |
| Edge Function unit tests | `deno test _shared/` (supabase/functions/) | 27 passed, 0 failed |
| Edge Function type check | `deno check ai-plan/index.ts ai-checkin/index.ts invite/index.ts delete-account/index.ts` | exit 0 |

Environment notes:
- `deno` is not on PATH. I used deno 2.9.6 from the npm `deno` package in `/tmp/claude-0/deno-scratch`, as in round 1. No deno version is pinned in docs/backend.md.
- Green suites still do not exercise the Dart-to-Supabase boundary, and `test/core/router/auth_redirect_test.dart` covers only the redirect function, not the route table. That is why the milestone dead end below is not caught.

## 2. Broken journeys (ranked)

### B1. HIGH: the milestone screen has no entry point (journey d, GAM-03)
- Route exists: `app/lib/features/gamification/gamification_routes.dart:24` `/projects/:id/milestone/:code`, built from `GamificationPaths.milestone(...)` (line 9).
- No caller: a grep for `GamificationPaths.milestone`, `/milestone/` and `milestone(` finds only the route definition and the helper. `checkin_result_screen.dart` `_apply` (around line 52-70) invalidates providers and calls `_leave()`, which goes to `/projects/:id`. It never checks `milestones_reached`.
- `project_detail_screen.dart:501-506` shows the milestone name in the stage list as plain text with no tap handler.
- Effect: a photo-confirmed milestone is recorded (`milestones_reached`, read by `gamification_repository.dart:102-130`), but the user is never sent to the celebration screen. The spec flow `14 "Áp dụng" → 16 → 12` is broken. The screen's own close button (`milestone_screen.dart:75-77`) is the only other navigation from it.
- Fix direction: after a successful apply, compare the milestones reached by this check-in and push `GamificationPaths.milestone(projectId, code)`. Also add a tap on reached milestones in project detail. Add a router test that asserts each named route is pushed from at least one caller.

### B2. MEDIUM: SET-01 notification toggles for "Được giao việc" and "Thành tích & huy hiệu" do nothing
- UI and storage exist: `settings_screen.dart:194-201` (`NotifType.assignment`, `NotifType.achievement`), persisted through `settings_providers.dart:34-50` and mirrored to `notification_prefs`.
- No consumer: `features/today/domain/reminder_planner.dart` checks only `NotifType.taskReminder` (line 144) and `NotifType.checkinReminder` (line 160). `grep NotifType.(assignment|achievement|household)` in lib finds only the settings screen and the domain defaults.
- No server sender in the repo: the four Edge Functions are `ai-plan`, `ai-checkin`, `invite` and `delete-account`. No FCM/push send exists, and `notification_prefs` is not read by any SQL function (grep of supabase/).
- Effect: the user can turn off assignment and achievement notifications and still receive them, once a sender exists. Right now nothing is sent, so the toggles are inert.

### B3. MEDIUM: household invite link across a sign-in is lost (journey e)
- Signed-out deep link: `household_routes.dart:58-72` stores the code in `pendingJoinCodeProvider` (in memory) and calls `router.go('/join?code=…')`. The auth redirect (`app_router.dart` `authRedirect`) sends the user to `/login`.
- After sign-in the redirect sends `/login → /today` (`app_router.dart`, signedIn branch). Nothing navigates back to `/join`.
- The code is shown again only in two places: `household_setup_screen.dart:24` (new users, step 2 of onboarding) and `household_screen.dart:63` (the Gia đình tab, for users without a household). A user who already has a household sees no prompt. The code is also lost if the app is killed during sign-in.
- Fix direction: after sign-in, if the pending code is set, route to `/join?code=…`. Persist the code (in local prefs) if it must survive a restart.

### B4. LOW: spec route drift for the Vườn tab and the web screen
- Spec §2 names the Vườn tab `/projects` (screen 06). The app uses `/garden` (`app_router.dart` `AppRoutes.garden`). `/projects` matches no route, so a link or deep link to it is a 404 (there is no `/projects` route, and `/projects/:id` needs an id).
- Spec §2 suggested routes include `/web` (screen 29, "P0 in canvas"). No route exists. It may be out of the mobile MVP list; the owner should confirm.
- Not a dead end inside the app, but docs and deep links should match.

### Navigation target inventory

Every navigation call in `app/lib` (`context.go/push/pushReplacement/pop`, `router.go`, `goBranch`, notification payloads). "Route" = a matching GoRoute exists in app_router.dart or a `*_routes.dart` file.

| Target (as written in code) | Called from (file:line) | Route exists |
|---|---|---|
| `/today` | profile_setup_screen.dart:144; household_setup_screen.dart:17, 83; join_screen.dart:38; task_detail_screen.dart:33; today_bootstrap.dart:109 (notification tap); reminder_planner.dart:305 (payload) | Yes (shell branch) |
| `/garden` | project_detail_screen.dart:49, 139; plant_search_screen.dart:70 | Yes (shell branch) |
| `/household` | household_screen.dart (tab); assign_task_screen.dart:78; invite_screen.dart:151; join_screen.dart:64 | Yes (shell branch) |
| `/household/invite` | household_setup_screen.dart:78; household_screen.dart:59, 123 | Yes |
| `/join?code=` | household_routes.dart:65 (deep link) | Yes |
| `/achievements` | milestone_screen.dart:273 | Yes (shell branch) |
| `/settings` | tab only | Yes (shell branch) |
| `/login` | auth redirect | Yes |
| `/config-error` | auth redirect | Yes |
| `/onboarding/profile` | settings_screen.dart:168; auth redirect | Yes |
| `/onboarding/household` | auth redirect | Yes |
| `/projects/new/search` | project_list_screen.dart:59, 134 | Yes |
| `/projects/new/context?plant=…` / `?name=…` | plant_search_screen.dart:33-38 | Yes |
| `/projects/:id` | project_list_screen.dart:117; plan_calendar_screen.dart:58; plan_review_screen.dart:44, 71; checkin_result_screen.dart:45; milestone_screen.dart:77; checkin_capture_screen.dart:45 (via `_base`) | Yes |
| `/projects/:id/generating?group=` | project_context_screen.dart:153-155; project_detail_screen.dart:232 | Yes |
| `/projects/:id/plan` | project_detail_screen.dart:234, 530; plan_calendar_screen.dart:142; generating_screen.dart:21 | Yes |
| `/projects/:id/calendar` | project_detail_screen.dart:175, 537; plan_review_screen.dart:173 | Yes |
| `/projects/:id/checkin` | project_detail_screen.dart:203; today_screen.dart:268 (`TodayRoutes.checkin`); reminder_planner.dart:370 (payload); checkin_retake_screen.dart:41 | Yes |
| `/projects/:id/checkin/retake` (extra: RetakeInfo or none) | checkin_capture_screen.dart:58, 69, 141 | Yes (retake registered before `:checkinId`) |
| `/projects/:id/checkin/:checkinId` | checkin_capture_screen.dart:67, 203 (pushReplacement); project_detail_screen.dart:646 | Yes |
| `/projects/:id/milestone/:code` | none | Route exists, no caller (B1) |
| `/task/:id` | today_screen.dart:417 | Yes |
| `/task/:id/assign` | task_detail_screen.dart:137 (`TodayRoutes.assign`) | Yes (household_routes.dart) |
| `/web` | none | No (B4) |
| `/projects` (spec tab route) | none | No, not used (B4) |

Result: 0 navigation targets without a route. 1 route without a caller (milestone).

Journey walk-through (code path, PASS / BREAK):
- (a) First launch → login → OTP → profile → household or skip → Today: PASS. Login OTP is an inline step on `login_screen.dart` (`loginOtpTitle`, `verifyOTP` in auth_repository.dart:55). Profile save goes to `/today`, and the household gate redirects to `/onboarding/household` if no household and not skipped. Skip sets the local flag and goes to `/today`. Back buttons are guarded by `canPop()`.
- (b) Vườn → "+" → search → context → generating → review → approve → detail → calendar: PASS. "+" at project_list_screen.dart:134. Free text path at plant_search_screen.dart:37-38. Did-you-mean "Có" at line ~206 uses `_openPlant`. Approve at plan_review_screen.dart:44 goes to `/projects/:id`.
- (c) Today → task detail → Done / Skip / Snooze → assign: PASS. Today row checkbox and action menu (today_screen.dart:404-508). Detail actions at task_detail_screen.dart:400, 408, 417. Assign at line 137, then `/household` after saving (assign_task_screen.dart:78).
- (d) Check-in banner and project detail → capture → retake / analyzing → result → approve → project: PASS, except the milestone step (B1). Retake from capture pushes with extra; the retake screen also works with no extra (checkin_retake_screen.dart:27-30).
- (e) Gia đình tab → invite → share; join via `/join?code=`: invite and share PASS (invite_screen.dart:44-109, share via ShareService). Join PASS when signed in; signed-out link BREAK (B3).
- (f) Thành tích tab: PASS (`/achievements`, achievements_screen.dart).
- (g) Settings: language PASS (settings_screen.dart:215-231 → locale_provider.dart and `updateLang`). Notifications PARTIAL (B2). Leave household PASS (leave_household.dart:50-60 → RPC `leave_household`, then skip flag and reload). Delete account PASS (two-step confirm, settings_screen.dart:63-81, then `delete-account` Edge Function, then local sign-out). Sign out PASS (`authRepository.signOut`, router goes to `/login`).

## 3. Feature coverage

The feature list itself (ID → title) is not in the repo. `docs/spec-mvp.md` cites the IDs in §3 and §6 but does not define them. Titles below are inferred from how each ID is used in the spec. The status is based on the code.

| ID | Feature (inferred) | Status | Evidence |
|---|---|---|---|
| ACC-01 | Sign-in: email code and Google | Done | `auth/presentation/login_screen.dart`; `auth/data/auth_repository.dart:42` (OAuth), `:51` (OTP send), `:55` (verify) |
| ACC-02 | Profile setup: name, province, language, experience | Partial | `profile/presentation/profile_setup_screen.dart`; `profile/data/profile_repository.dart:49` (update, round 1 fix). No timezone UI (spec §7 #9). Avatar upload at `profile_repository.dart:90` |
| ACC-03 | Location stored at region level | Partial | Province picker `profile/domain/provinces.dart`, stored as province_code / zone_code. No GPS button (spec 02 shows one) |
| ACC-05 | Delete account and all data | Done | `settings/presentation/settings_screen.dart:63-82, 271-281`; `auth/data/auth_repository.dart:61-63` (Edge Function `delete-account`); `supabase/functions/delete-account/index.ts` |
| PRJ-01 | Project list | Done | `projects/presentation/project_list_screen.dart`; `projects_providers.dart` |
| PRJ-02 | Create project: name, start date, pots, start stage, space, sun, pot, watering | Done | `projects/presentation/project_context_screen.dart:135-155`; `projects/data/project_repository.dart:134-149` |
| PRJ-03 | Context and optional cover photo | Done | `project_context_screen.dart:106` (ImagePicker); `project_repository.dart:157-167` (cover upload, `checkins` bucket) |
| PRJ-04 | Status filter: active, done, archived | Done | `project_list_screen.dart:63-106, 143` |
| PRJ-06 | Project detail: stage, progress, stats, history, actions | Done | `projects/presentation/project_detail_screen.dart`; `projects/domain/project_progress.dart` |
| PLT-01 | Plant search (catalogue) | Done | `plants/presentation/plant_search_screen.dart`; `plants/domain/plant_search.dart`; `plants/data/plant_repository.dart` |
| PLT-02 | Search results: match, name, difficulty, harvest time | Done | `plant_search_screen.dart:~150-250`; `plants/domain/plant.dart` |
| PLT-03 | Unknown plant: free text and "Did you mean" suggestions | Done | `plant_search_screen.dart:37-38, 176-232` (suggestion "Có" → `_openPlant`, "Không phải" dismisses; spec §7 #12 left it without a target) |
| PLN-01 | AI plan generation with progress screen | Done | `plan/presentation/generating_screen.dart`; `plan/data/plan_repository.dart:47-65` (`ai-plan` invoke, response check) |
| PLN-02 | Plan review by stage | Done | `plan/presentation/plan_review_screen.dart` |
| PLN-03 | Task detail: how-to steps, why, safety text | Done | `today/presentation/task_detail_screen.dart:61-202` (`taskSteps`, `taskWhy`) |
| PLN-04 | Calendar view of the plan | Done | `plan/presentation/plan_calendar_screen.dart` |
| PLN-05 | Add, edit, delete (archive) tasks | Done | `plan/data/plan_repository.dart:159-197` (`addTask`, `updateTask`, `deleteTask` as soft delete); `plan/presentation/task_edit_sheet.dart`; `plan_calendar_screen.dart:225` |
| PLN-07 | Approve plan (materializes occurrences) | Done | `plan_review_screen.dart:44`; `plan_repository.dart:123` (`approve_plan`); `today/data/task_repository.dart:56` (`materialize_occurrences`) |
| PLN-09 | Organic-first note and per-task safety text | Done | `plan_review_screen.dart:281` (organic note); `plan/domain/template_renderer.dart`; `prefer_organic` in `profile/domain/user_profile.dart` |
| CHK-01 | Check-in schedule and due banner on Today | Done | `today/presentation/today_screen.dart:268`; `today/domain/checkin_due.dart`; `today/domain/reminder_planner.dart:368-370` (local reminder) |
| CHK-02 | Photo capture (camera and gallery) | Done | `checkin/presentation/checkin_providers.dart:18-41` (`PickerImageSource`); `checkin_capture_screen.dart` |
| CHK-03 | Quick condition tags | Done | `checkin_providers.dart:224-227` (`toggleTag`); `checkin_capture_screen.dart:304` (`checkinQuickTags`) |
| CHK-04 | Result: stage, health, problems, confidence band | Done | `checkin/presentation/checkin_result_screen.dart`; `checkin/domain/checkin_models.dart` |
| CHK-05 | Accept selected changes and apply | Done | `checkin_result_screen.dart` `_apply`; `checkin/data/checkin_repository.dart:167-173` (`apply_checkin_changes`, defined in migration 0200) |
| CHK-06 | Blur/dark rejected on device, retake screen | Done | `checkin/domain/image_quality.dart`; `checkin_providers.dart:117, 242` (RetakeInfo); `checkin_retake_screen.dart` |
| TSK-01 | Today list grouped by time window | Done | `today/presentation/today_screen.dart`; `today/domain/today_builder.dart` |
| TSK-02 | Done, Skip, Snooze (offline, outbox sync) | Done | `today/presentation/task_actions.dart:64-183` (snooze sheet); `task_detail_screen.dart:400-417`; `today/data/today_local_store.dart` (outbox); `today/data/outbox_syncer.dart` |
| TSK-04 | Bundle reminders into one daily notification | Done | Setting `settings_screen.dart:204`; `reminder_planner.dart:153, 260` |
| TSK-06 | Project history of task actions | Done | `project_detail_screen.dart:257, 320` (`taskHistoryProvider`, "Lịch sử gần đây") |
| GAM-01 | XP, levels, streak header | Done | `gamification/presentation/achievements_screen.dart`; `gamification/domain/xp.dart`, `levels.dart`; `levels` table seeded (migration 0400:65) |
| GAM-03 | Milestone celebration screen | Partial | Screen built (`gamification/presentation/milestone_screen.dart`) and routed (`gamification_routes.dart:24`), but nothing navigates to it (B1) |
| GAM-04 | Achievements and badges | Done | `achievements_screen.dart`; `gamification_repository.dart:31` (`badges_catalog`); catalogue seeded (migration 0400:74) |
| GAM-08 | Anti-cheat: photo-confirmed milestone XP, daily cap, server time | Done | Server rules in `supabase/migrations/20261019000200_functions.sql` (comments around line 228, XP triggers); client has no write path to `users.xp_total` (RLS, spec §4) |
| HSH-01 | Invite: code, link, email or phone | Done | `household/presentation/invite_screen.dart:44-109`; `household/data/household_repository.dart:199-204` (`invite` function); `supabase/functions/invite/` |
| HSH-02 | Create household, join by code or link | Done | `household_setup_screen.dart`; `join_screen.dart`; `household_repository.dart:151, 160` (`create_household`, `accept_invite`); deep links `household_routes.dart:58-72` (B3 for signed-out) |
| HSH-03 | Share a project to the household | Done | `household_screen.dart:367-400`; `household_repository.dart:223-244` (`setProjectHousehold`) |
| HSH-04 | Assign task: once, series, rotation | Done | `household/presentation/assign_task_screen.dart`; `household_repository.dart:40-41` (`assignTask`). No assignee notification is sent (B2) |
| HSH-06 | Activity feed | Done | `household_repository.dart:252` (`household_activity`, realtime); `household_screen.dart` |
| HSH-09 | Leave household (ownership handover) | Done | `household/presentation/leave_household.dart:50-60`; `household_repository.dart:177` (`leave_household`); `settings_screen.dart:237-250` |
| SET-01 | Notification toggles | Partial | UI `settings_screen.dart:175-206`; enforced only for task and check-in reminders (`reminder_planner.dart:144, 160`). Assignment and achievement toggles have no consumer (B2) |
| SET-02 | Language switch | Done | `settings_screen.dart:215-231`; `settings/presentation/locale_provider.dart`; `profile_repository.dart` `updateLang` |

Totals: 41 IDs listed in the brief. Done 37, Partial 4 (ACC-02, ACC-03, GAM-03, SET-01), Missing 0.

## 4. Hard-coded strings

Check: grep for `Text('…')`, `SnackBar(content: Text('…'))`, and named arguments (`label`, `title`, `hint`, `tooltip`, `message`, …) with literal text in `app/lib` outside `l10n/`. Result: no literal user-facing `Text` or named-argument strings. Offenders are the following.

| File:line | String | Impact |
|---|---|---|
| `app/lib/features/today/data/notification_gateway.dart:39` | Android channel name "Nhắc việc chăm cây" | Shown in Android notification settings. Vietnamese in both locales. Medium |
| `app/lib/features/today/data/notification_gateway.dart:40` | channelDescription "Nhắc việc chăm cây theo khung giờ" | Same. Medium |
| `app/lib/features/today/data/notification_gateway.dart:46` | Android channel name "Nhắc chụp check-in" | Same. Medium |
| `app/lib/features/today/data/notification_gateway.dart:47` | channelDescription "Nhắc chụp ảnh check-in cho cây" | Same. Medium |
| `app/lib/features/gamification/domain/levels.dart:45-52` | Level names, Vietnamese only (`LevelDef(…, 'Người mới')` etc.) | Fallback only when the `levels` table is empty (`achievements_models.dart:109, 119`). Low |
| `app/lib/features/gamification/domain/streak_badges.dart:131-142` | Badge names, Vietnamese only (`BadgeDef(…, 'Hạt giống đầu tiên', …)`) | Not referenced from `app/lib` outside this file. Dead or test-only data. Low |
| `app/lib/features/gamification/presentation/achievements_screen.dart:161, 168, 179` | `'+${…} XP'` (XP suffix literal) | Abbreviation in both locales. Low |
| `app/lib/features/auth/presentation/login_screen.dart` (Google button) | Glyph `'G'` | Brand mark. Acceptable |
| `app/lib/features/profile/domain/provinces.dart:18-51` | Province names (Vietnamese proper nouns) | Acceptable as proper nouns. English locale still shows e.g. "TP. Hồ Chí Minh" (settings_screen.dart:96). Low |

Also checked: the ARB files have matching key sets (round 1). No English leftover values in `app_vi.arb` other than brand and intentional words.

## 5. Other risks

1. Invite code strength (medium). `supabase/migrations/20261019000200_functions.sql:526` makes codes `VUON-` plus 4 digits, a 10,000-value space. `accept_invite` allows 10 attempts per user per hour (line 552), so brute force across many accounts is possible. Codes do expire (`expires_at`, line 563). Consider longer codes or a per-IP or global limit.
2. Storage cleanup on account delete (low). `supabase/functions/delete-account/index.ts:23` lists only the top level of `{uid}/` and keeps files with an `id` there. Files under `{uid}/{projectId}/` that no DB row references (for example, an upload whose `checkins` insert failed) are not removed.
3. Notification senders missing (medium). No FCM or push sender for assignment, achievement or household activity exists in the repo (see B2). The "Được giao việc" promise in spec §6.7 depends on it.
4. Join code in memory only (low). See B3.
5. Route tests (medium, process). `app/test/core/router/auth_redirect_test.dart` covers only the redirect function. A test that every GoRoute has a caller, or that every `context.go/push` target matches a route, would have caught B1 and B4.
6. Spec and route drift (low). `/garden` vs `/projects` for the Vườn tab, and `/web` not built (B4). Keep docs/spec-mvp.md §2 and the router in step.
7. Round 1 regression check (pass). Verified in code: C1 profile update (`profile_repository.dart:49`), C2 member project insert (migration 0500), C3 `dayOffset` in `Task` and scheduler (`task_scheduler.dart:63`, `models.dart:146, 194`), C4 `fixed_date` (`task_scheduler.dart:88`, `task_edit_sheet.dart:111-114`), C5 delete via Edge Function (`auth_repository.dart:63`), C6 `member_profiles` (`task_repository.dart:121`, `household_repository.dart:96`), C7 `name_en` (`plan/domain/models.dart:90-118`), C8 consents (`profile_repository.dart:63-74`), C12 storage update policy (migration 0500:17). All five SQL suites still green.
8. RPC names (pass). Every `rpc('…')` used in `app/lib` exists as a function in `supabase/migrations`. Every table the app queries exists (only `avatars` is not a table, and it is a storage bucket).
9. Check-in reminders are local only (note). The client schedules them (`reminder_planner.dart`). Spec §6.7 says `pg_cron`. Both can coexist, but this should be decided.
10. Not tested in this round: live Anthropic calls, Google and email delivery, Realtime, push delivery, and real device camera and notification behaviour.

## 8. Resolution (fix round after QA round 2)

Each line names the fix. Test counts at the end of this section.

- **B1 (milestone dead end): fixed.** `checkin_result_screen.dart` `_apply` now replaces itself with `GamificationPaths.milestone(projectId, code)` when the result has `milestoneIsNew` and a milestone code (and the result was not already applied); closing the celebration returns to the project. Project detail's plan tab shows reached milestones (new `reachedMilestonesProvider` / `GamificationRepository.reachedMilestones`) as tappable rows (`milestone-<CODE>`) that reopen the screen. Tests: checkin flow (new milestone opens `/milestone/…`, no new milestone returns to the project), project detail (only reached milestones are tappable and navigate), route coverage test (see Route tests).
- **B2 (push for assignment, achievement, household activity): fixed.** New Edge Function `supabase/functions/send-push` (FCM HTTP v1, service account in `FCM_SERVICE_ACCOUNT`, RS256 JWT via WebCrypto, access token cached). Migration `20261019000600_qa2_fixes.sql` adds SQL triggers (`pg_net`) on `tasks.assignee_id` change, `user_badges` insert and `household_activity` insert (to the other members) plus the server-only `private_config` table. The function honours `notification_prefs` per type and quiet hours (per-type override, else `users.quiet_*`, in the user's timezone) and deletes tokens FCM reports `UNREGISTERED`. The app deletes its device's `push_tokens` row on sign-out (`signOutProvider` / `removeDeviceToken`). Setup in `docs/backend.md` §6. Tests: 12 Deno tests with mocked `fetch` and an in-memory store (`fcm_test.ts`, `push_test.ts`), a SQL test that stubs `net.http_post` and checks payloads, self-assignment and the unconfigured case, and two Flutter sign-out tests.
- **B3 (invite link lost across sign-in): fixed.** `pendingJoinCodeProvider` is mirrored to LocalSettings (`pending_join_code`) and restored on start; `authRedirect` takes `pendingJoinCode` and sends a signed-in user (profile complete, household state known) to `/join?code=…`; `JoinScreen` consumes the saved code once it is shown; users already in a household see "Bạn đã ở trong một gia đình" with a button to the Gia đình tab instead of the code form. Tests: redirect rules, persistence round trip, garbage in store, join screen consumption and already-member message.
- **B4 (spec drift): fixed.** `/projects` now redirects to `/garden` (`projectsAliasRoute`, widget test); spec §2/§3 and §6.7 updated. `/web` stays out of the mobile MVP and is documented as having no route.
- **Risk 1 (invite code strength): fixed.** Codes are `VUON-` + 6 characters of `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (~8.9e8 combinations) from `create_invite` in the new migration (applied migrations untouched); rate limits unchanged (10 failed attempts per user per hour, 20 invites per household per day). App validation/normalisation accept the new format and, for the 7 days they live, legacy 4-digit codes; ARB hints updated. SQL tests: format and alphabet over 15 generated codes, the invite cap, lock-out after 10 bad attempts (even for a valid code). Dart tests: parsing, normalisation, ambiguous characters rejected.
- **Risk 2 (storage cleanup on delete-account): fixed.** `_shared/storage_cleanup.ts` lists `{uid}/` recursively (paging, any depth) in `avatars` and `checkins` and merges the paths the database knows; `delete-account` uses it and fails loudly if a listing fails. Deno tests: nested per-project folders, a user whose id is a prefix of another's, paging, error propagation, merge with database paths.
- **Risk 3 (notification senders missing): fixed with B2.**
- **Risk 4 (join code in memory only): fixed with B3.**
- **Risk 5 (route tests): fixed.** `test/core/router/route_coverage_test.dart` builds the real router, asserts every registered route has a caller in `lib/` (path constants and builders such as `GamificationPaths.milestone` are followed to their references) unless it is listed as a tab, deep link, auth redirect or spec alias, and that every literal `go/push/pushReplacement` target matches a route. Checked by mutation: removing the two milestone callers makes it fail with `['/projects/:id/milestone/:code']`.
- **Risk 6 (spec and route drift): fixed with B4.**
- **Risk 9 (check-in reminders local vs `pg_cron`): decided, local.** Local notifications work offline and need no server job; spec §6.7 and `docs/backend.md` §5 say so. No `pg_cron`.
- **Hard-coded strings (section 4): fixed.** Notification channel names/descriptions come from ARB (`notifChannel*`, passed through `ReminderTexts.channels`; the Android channels are re-created so a language switch renames them); the "+N XP" labels use `gamXpGain`; fallback level names (`Levels.defaults`) and badge names (`Badges.catalog`) carry English names (`LevelDef.nameEn`, `BadgeDef.nameEn`) and `levelName` uses them. Province names and the Google "G" stay as accepted. Test: `test/l10n/localized_strings_test.dart`.

