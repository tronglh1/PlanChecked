# Architecture & conventions – Vườn Nhà (PlanChecked)

Stack (locked 2026-10-19): **Flutter (Android first; iOS/Web later from the same code) + Supabase**. Firebase is used only for FCM push (and optionally Crashlytics). Full plan: see the project's `ke-hoach-lam-app-android.md`; product spec digest: `docs/spec-mvp.md`.

## Repository layout

```
app/                      Flutter app (package name: vuon_nha, applicationId: com.planchecked.vuonnha)
  lib/
    main.dart             bootstrap: env, Supabase.initialize, ProviderScope
    app.dart              MaterialApp.router, theme, l10n
    core/
      env.dart            SUPABASE_URL / SUPABASE_ANON_KEY via --dart-define
      theme/              tokens.dart, app_theme.dart
      widgets/            GlassCard, GlowButton, GlassScaffold (blob background), TagChip, ProgressRing, ...
      router/             app_router.dart (go_router, StatefulShellRoute for 5 tabs)
      db/                 drift local database + offline outbox
      utils/              vi_normalize.dart (strip Vietnamese diacritics), date/time-window helpers
    features/<feature>/
      data/               repositories (Supabase + drift), DTOs
      domain/             pure Dart models + rules (unit-tested, no Flutter imports)
      presentation/       screens, widgets, Riverpod providers/controllers
  l10n/                   app_vi.arb (template, default), app_en.arb
  test/                   mirrors lib/
supabase/
  migrations/             timestamped SQL: schema, RLS, functions, seed of codes
  seed/                   plant DB seed (plants, task/problem codes, VN/EN text templates)
  functions/              Edge Functions (Deno/TypeScript): ai-plan, ai-checkin, award-xp, invite, delete-account
  config.toml
.github/workflows/        ci.yml (analyze + test), android-release.yml (build AAB/APK)
docs/
```

Features: `auth`, `profile`, `plants`, `projects`, `plan`, `today`, `checkin`, `household`, `gamification`, `settings`.

## Packages (pin with ^ to latest stable at scaffold time)
flutter_riverpod (+ riverpod_annotation optional, keep it simple: plain Notifier/AsyncNotifier, no codegen required), go_router, supabase_flutter, drift + drift_flutter (+ drift_dev, build_runner dev), flutter_local_notifications, timezone, firebase_core + firebase_messaging, image_picker / camera, image, intl, flutter_localizations, google_fonts (Be Vietnam Pro) or bundled font, lottie, share_plus, app_links, uuid.

## Conventions
- Domain logic (scheduling, time windows, XP, anti-cheat, text rendering from codes, fuzzy search) lives in `domain/` as pure Dart with unit tests. UI never computes business rules.
- Repositories are abstract classes with a Supabase implementation, so tests use fakes. Providers expose repositories; screens never call Supabase directly.
- All user-visible strings go through l10n (`AppLocalizations`); Vietnamese is the template ARB. Plant/task/problem guidance text comes from DB `text_templates` by code + locale, never hard-coded.
- AI is server-only. The app calls Edge Functions `ai-plan` and `ai-checkin`; the API key lives only in Supabase secrets (`GEMINI_API_KEY` or `ANTHROPIC_API_KEY`, picked in `_shared/ai.ts`). AI returns codes + params; the app renders text from templates. Models: a cheap default (`gemini-3.5-flash-lite` / `claude-haiku-5-5`), escalating to a stronger one (`gemini-3.8-flash` / `claude-sonnet-5-5`) on low confidence or unknown plant.
- Security: every table has RLS. Access rule: a row is visible to its owner, or to members of the household the project is shared with. Photos in private bucket `checkins`, path `{household_or_user}/{project}/{uuid}.jpg`, read via signed URLs.
- XP is computed server-side (`award-xp` function / SQL function), client only displays.
- Offline (MVP scope): Today's tasks cached in drift; Done/Skip/Snooze written to an outbox table and flushed when online; server uses the client timestamp but validates it.
- Reminders: own tasks scheduled as local notifications; household events via FCM sent from the server.
- Design: light frosted glass. Use tokens from `core/theme/tokens.dart` only; no ad-hoc colors in screens. Primary CTAs are glossy orange gradient with WHITE text/icons and an orange glow; no green outlines on buttons. Green only for progress, selected state, active tab.
- Lints: `flutter_lints` + `prefer_const_constructors`. `flutter analyze` must be clean and `flutter test` green before a milestone is done.
- Config: run with `--dart-define-from-file=env/dev.json` (gitignored; `env/example.json` committed).

## Environment notes
- The agent container has the Flutter SDK at `/home/claude/sdk/flutter/bin` but no Android SDK; `flutter analyze` and `flutter test` run locally, APK/AAB builds run in GitHub Actions.
