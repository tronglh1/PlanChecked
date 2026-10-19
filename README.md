# Vườn Nhà (PlanChecked)

Ứng dụng chăm sóc cây: Flutter (Android trước, iOS/Web sau) + Supabase. Kiến trúc và quy ước: [docs/architecture.md](docs/architecture.md).

## Bắt đầu nhanh (dành cho chủ app)

### 1. Cài đặt trên máy Windows
- [Git](https://git-scm.com/download/win), [Flutter 3.47.7 stable](https://docs.flutter.dev/install) (đặt vào PATH), [Android Studio](https://developer.android.com/studio) (kèm Android SDK, JDK 17 có sẵn trong gói), Node.js 20+ (để chạy test SQL), [Supabase CLI](https://supabase.com/docs/guides/cli) (`scoop install supabase` hoặc `npm i -g supabase`).
- Kiểm tra: `flutter doctor` (chấp nhận licence: `flutter doctor --android-licenses`).

### 2. Tạo project Supabase và áp dụng backend
1. Vào https://supabase.com tạo project, vùng **Southeast Asia (Singapore)**, lưu mật khẩu DB.
2. Trong thư mục repo:
   ```powershell
   supabase login
   supabase link --project-ref <ref>
   supabase db push --include-seed          # migrations + seed cây/mã/câu hướng dẫn
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...   # đặt giới hạn chi tiêu trên console.anthropic.com
   supabase functions deploy ai-plan ai-checkin invite delete-account --no-verify-jwt
   ```
3. Cấu hình đăng nhập Google, email OTP (SMTP riêng), Redirect URL `io.supabase.vuonnha://login-callback/`: làm theo [docs/backend.md](docs/backend.md) mục 1.
4. Lấy **Project URL** và **anon key** ở Settings > API.

### 3. Đặt khoá cấu hình
- Local: `cd app`, sao chép `env/example.json` thành `env/dev.json` (chạy thử) và `env/prod.json` (bản phát hành), điền `SUPABASE_URL` và `SUPABASE_ANON_KEY`. Hai file này nằm trong .gitignore.
- GitHub Actions: tạo các secret theo [docs/ci-secrets.md](docs/ci-secrets.md) (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, 4 secret ký ứng dụng, tuỳ chọn `GOOGLE_SERVICES_JSON`).
- Khoá Claude API chỉ nằm trong Supabase secrets, không bao giờ đưa vào app hay GitHub.

### 4. Build trên máy Windows
```powershell
cd app
flutter pub get
flutter run --dart-define-from-file=env/dev.json          # chạy thử trên máy/emulator
flutter build appbundle --release --dart-define-from-file=env/prod.json   # file AAB để đưa lên Play
flutter build apk --release --dart-define-from-file=env/prod.json         # APK cài thủ công
```
Kết quả: `app/build/app/outputs/bundle/release/app-release.aab`. Để ký bản release, tạo `app/android/key.properties` (đã gitignore; xem [docs/ci-secrets.md](docs/ci-secrets.md)). Tăng `version: x.y.z+N` trong `app/pubspec.yaml` trước mỗi lần tải lên Play (N phải tăng).

### 5. Build bằng GitHub Actions
- Chạy tay: tab **Actions** > "Android release" > Run workflow (tick `require_signing` nếu cần bản ký thật), hoặc đẩy tag: `git tag v1.0.0 && git push origin v1.0.0`.
- Tải AAB/APK ở mục Artifacts của lần chạy (kèm `mapping.txt` để đọc crash).
- Trang chính sách quyền riêng tư: bật Settings > Pages > Source = **GitHub Actions**, rồi chạy workflow "Publish site".

### 6. Tài liệu
- Kiến trúc: [docs/architecture.md](docs/architecture.md) · Backend: [docs/backend.md](docs/backend.md) · Đặc tả: [docs/spec-mvp.md](docs/spec-mvp.md)
- Phát hành Play: [docs/play-store/release-checklist.md](docs/play-store/release-checklist.md), [data-safety](docs/play-store/data-safety.md), [content-rating](docs/play-store/content-rating.md), mô tả cửa hàng [VI](docs/play-store/store-listing.vi.md) / [EN](docs/play-store/store-listing.en.md)
- Quyền riêng tư: [VI](docs/privacy-policy.vi.md) / [EN](docs/privacy-policy.en.md); trang web trong [docs/site/](docs/site/)
- Secrets CI: [docs/ci-secrets.md](docs/ci-secrets.md)

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

Workflow `.github/workflows/android-release.yml` (chạy tay hoặc khi push tag `v*`) chạy analyze + test rồi build APK + AAB, ghim Flutter 3.47.7 và Java 17. Bản release bật R8 (shrink code + resource); `mapping.txt` được lưu làm artifact. Tag `v*` bắt buộc đủ secret ký. Chi tiết secrets: [docs/ci-secrets.md](docs/ci-secrets.md); các bước lên Play: [docs/play-store/release-checklist.md](docs/play-store/release-checklist.md). Local: đặt `app/android/key.properties` (gitignore) để ký release.
