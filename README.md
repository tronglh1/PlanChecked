# Vườn Nhà (PlanChecked)

Ứng dụng chăm sóc cây: Flutter (Android trước, iOS/Web sau) + Supabase. Kiến trúc và quy ước: [docs/architecture.md](docs/architecture.md).

## Chạy app

Yêu cầu: Flutter stable (Dart >= 3.13), Android SDK để chạy trên máy/emulator.

```bash
cd app
flutter pub get
cp env/example.json env/dev.json   # điền SUPABASE_URL và SUPABASE_ANON_KEY
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` đã được gitignore. Nếu thiếu cấu hình, app hiển thị màn hình báo lỗi cấu hình thay vì crash.

## Supabase

Tạo project tại https://supabase.com, lấy Project URL và anon (publishable) key ở Settings > API.
Schema, RLS, seed và Edge Functions nằm trong thư mục `supabase/` (xem docs/architecture.md); áp dụng bằng Supabase CLI (`supabase db push`, `supabase functions deploy`). Khoá Claude API chỉ đặt trong Supabase secrets (`ANTHROPIC_API_KEY`).

## Lệnh thường dùng

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # drift
flutter gen-l10n
```

## Phát hành Android

Workflow `.github/workflows/android-release.yml` (chạy tay hoặc khi push tag `v*`) build APK + AAB. Secrets cần: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (tuỳ chọn `SUPABASE_URL`, `SUPABASE_ANON_KEY`). Thiếu secrets thì build ký bằng debug key. Local: đặt `android/key.properties` (gitignore) để ký release.
