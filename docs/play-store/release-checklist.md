# Release checklist – Vườn Nhà on Google Play

Owner actions are marked **[owner]**. Everything else is already in the repo.

## 0. Before the first build
- [ ] **[owner]** Supabase project in Singapore, migrations + seed + functions deployed (see `README.md` and `docs/backend.md` section 1).
- [ ] **[owner]** Seed content reviewed; toxic-plant flags checked; then `update plants set data_status='verified'` (and `text_templates`).
- [ ] **[owner]** Replace `<EMAIL_LIÊN_HỆ>` in `docs/privacy-policy.*.md`, `docs/site/*.html`, store listings; run `python3 docs/site/build.py`.
- [ ] **[owner]** Publish the site: repo Settings > Pages > Source = GitHub Actions, run workflow "Publish site". Privacy URL = `https://<user>.github.io/<repo>/privacy.html`, deletion URL = `.../delete-account.html`.
- [ ] **[owner]** If you own `vuonnha.app`: host `/.well-known/assetlinks.json` for App Links (`autoVerify` intent filter for `/i`), using the **app-signing** SHA-256. Otherwise remove that intent filter or accept that the custom scheme `vuonnha://join` is used.
- [ ] **[owner]** Firebase project, add Android app `com.planchecked.vuonnha`, download `google-services.json` into secret `GOOGLE_SERVICES_JSON` (see `docs/ci-secrets.md`). Without it the app builds but push is off.
- [ ] **[owner]** Real app icon and name (the vector icon in `app/android/app/src/main/res` is a placeholder). Export 512x512 for the store.

## 1. Signing: upload key and Play App Signing
1. Create the upload keystore once (keep two offline backups):
   `keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
2. Put the secrets in GitHub (`docs/ci-secrets.md`) or `app/android/key.properties` for local builds (`storeFile` is relative to `app/android/app/`).
3. In Play Console choose **Play App Signing** (default and mandatory for new apps). Google re-signs releases with the **app signing key**; your key is only the **upload key**.
4. Collect both SHA-1 fingerprints:
   - Upload key: `keytool -list -v -keystore upload-keystore.jks -alias upload` (or `./gradlew signingReport` in `app/android`).
   - App signing key: Play Console > Test and release > App integrity > App signing > "App signing key certificate" SHA-1 (and SHA-256).
   - Debug key: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` (Windows: `%USERPROFILE%\.android\debug.keystore`).
5. **Add BOTH the upload and the app-signing SHA-1 (plus debug for development)** wherever a SHA-1 is registered:
   - Google Cloud Console > APIs & Services > Credentials: one **Android** OAuth client per fingerprint for package `com.planchecked.vuonnha`.
   - Firebase project settings > your Android app > Add fingerprint (all three) and re-download `google-services.json`.
   - Supabase: Authentication > Providers > Google uses the **Web** client id/secret; Android SHA-1s live in Google/Firebase, not in Supabase. Today the app signs in with Supabase's browser OAuth flow (redirect `io.supabase.vuonnha://login-callback/`), which does not need SHA-1, but keep all fingerprints registered so native Google sign-in and Firebase keep working on the Play build. Missing the app-signing SHA-1 is the classic "Google sign-in works in testing but fails when installed from Play" bug.
6. Verify the Supabase Redirect URL `io.supabase.vuonnha://login-callback/` is allow-listed.

## 2. Pre-flight checks (every release)
- [ ] `flutter analyze` and `flutter test` green (CI does this).
- [ ] Bump `app/pubspec.yaml` `version: x.y.z+N`; **N (versionCode) must increase on every upload**.
- [ ] **Target SDK**: Google requires new apps/updates to target the API level of the previous Android release (Android 15 / API 35 from Aug 2025; API 36 from Aug 2026 - check https://developer.android.com/google/play/requirements/target-sdk at release time). `build.gradle.kts` takes `targetSdk`/`compileSdk` from the Flutter SDK (pinned 3.47.7) and fails the build if `targetSdk < 35`. After a build, confirm with `aapt dump badging app-release.apk | grep targetSdkVersion` (or Play Console pre-launch report). If Play raises the bar, upgrade the Flutter pin in both workflows.
- [ ] 16 KB page size: new submissions targeting Android 15+ must support 16 KB pages. Flutter 3.47 and current plugins do; run Play's pre-launch report to confirm native libs (sqlite3, etc.).
- [ ] Release build: `cd app && flutter build appbundle --release --dart-define-from-file=env/prod.json`; install the APK on a real low-end device and test sign-in, offline Today, check-in photo, push, account deletion with **R8 enabled** (shrinking can break reflection; no Gradle build could be run in the authoring environment).
- [ ] Upload `mapping.txt` (CI artifact `vuon-nha-mapping-*`) with each release for readable crash stacks.

## 3. Tracks
### 3a. Internal testing (immediately, up to 100 testers)
- [ ] Create the app in Play Console (default language Vietnamese, free app).
- [ ] Upload the AAB (from CI artifact `vuon-nha-android-vX.Y.Z`) to Internal testing, add tester emails, share the opt-in link.
- [ ] Use it daily with family; fix blockers. Check the pre-launch report.

### 3b. Store setup (App content) before Closed testing
- [ ] Privacy policy URL, Data safety (`docs/play-store/data-safety.md`), Content rating (`content-rating.md`), Target audience 16+, Ads: No, App access instructions with a test account, Account deletion URL, Store listing (`store-listing.vi.md` default, `.en.md` translation), icon 512, feature graphic, screenshots.
- [ ] Personal developer account (created after Nov 2023): verify identity (ID, phone, device), pay the 25 USD fee.

### 3c. Closed testing (mandatory for personal accounts: 12 testers x 14 days)
- [ ] Create a Closed testing track, add **at least 12 testers** (Google accounts) via an email list or Google Group; testers must **opt in and stay opted in 14 continuous days**. Recruit about 20 to survive drop-outs.
- [ ] Promote the same AAB (or a newer one) to Closed testing. Testers must install from Play.
- [ ] Ask testers to open the app on several of the 14 days; collect feedback; ship fixes as new versionCodes.
- [ ] After day 14 with 12+ opted-in: Play Console > Dashboard > "Apply for production" and answer the questions (testing summary, readiness).
- [ ] Organisation accounts (D-U-N-S) skip this requirement.

### 3d. Production (staged rollout)
- [ ] Create the production release, release notes from `store-listing.*.md`, rollout **10%**.
- [ ] Watch Android vitals, crashes/ANRs, Supabase logs and Anthropic spend for 2-3 days; then **50%**, then **100%**. Halt rollout if crash-free users < 99%.
- [ ] Keep the git tag `vX.Y.Z` matching `pubspec.yaml` and the Play versionCode.

## 4. After launch
- [ ] Review `ai_usage` costs and set Anthropic spend alerts.
- [ ] Respond to user reviews and deletion emails within 72 hours (policy promise).
- [ ] Re-check Data safety whenever an SDK or data field changes; policy version `kConsentVersion` must be bumped when the privacy policy changes materially.
