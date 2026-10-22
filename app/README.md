# vuon_nha

A new Flutter project.

## Auth setup (M1)

Login supports Google and email OTP (no Apple). Google uses Supabase's browser
OAuth (PKCE) flow with a deep-link callback; no extra Flutter package.

1. Google Cloud Console: create an OAuth client of type **Web application**.
   Authorized redirect URI: `https://<project-ref>.supabase.co/auth/v1/callback`.
2. Supabase Dashboard > Authentication > Providers > Google: enable and paste
   the client id and secret.
3. Supabase Dashboard > Authentication > URL Configuration > Redirect URLs:
   add `io.supabase.vuonnha://login-callback/`.
4. The Android intent-filter for scheme `io.supabase.vuonnha`, host
   `login-callback` is already in `AndroidManifest.xml`. For iOS later, add the
   same scheme under `CFBundleURLTypes` in `Info.plist`.
5. Email OTP: make the "Magic Link" and "Confirm signup" email templates show
   `{{ .Token }}` so users receive a 6-digit code.
6. Backend must provide: table `users` (RLS: own row), `notification_prefs`
   (unique on `user_id,type`), RPC `delete_my_account`, storage bucket
   `avatars` (path `{uid}/avatar.jpg`), and `plants` / `text_templates`
   readable by authenticated users.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
