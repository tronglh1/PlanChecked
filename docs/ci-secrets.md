# CI secrets (GitHub Actions)

Set them in the repo: **Settings > Secrets and variables > Actions > New repository secret**. They are used by `.github/workflows/android-release.yml` (never by `ci.yml`, which needs none).

| Secret | Required | What it is |
|---|---|---|
| `SUPABASE_URL` | Yes | Project URL, e.g. `https://abcd1234.supabase.co` (Supabase > Settings > API) |
| `SUPABASE_ANON_KEY` | Yes | The anon / publishable key from the same page. Safe to ship in the app; **never** use the service-role key |
| `ANDROID_KEYSTORE_BASE64` | For Play uploads | Base64 of your upload keystore `.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | For Play uploads | Keystore (store) password |
| `ANDROID_KEY_ALIAS` | For Play uploads | Key alias (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | For Play uploads | Key password (often equal to the store password) |
| `GOOGLE_SERVICES_JSON` | Optional | Full contents of Firebase `google-services.json`; without it the app builds with push disabled |

Tag builds (`git tag v1.0.0 && git push origin v1.0.0`) and manual runs with `require_signing = true` **fail** if any signing secret is empty, so you never publish a debug-signed AAB by accident. Without signing secrets, manual runs produce debug-signed artifacts for internal sideload tests only.

## How to create each one

### SUPABASE_URL / SUPABASE_ANON_KEY
Supabase Dashboard > your project > Settings > API > copy "Project URL" and the "anon public" (or "publishable") key. The same two values go into `app/env/prod.json` for local builds.

### Upload keystore (once; back it up in two places)
```powershell
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```
`keytool` ships with the JDK / Android Studio (`C:\Program Files\Android\Android Studio\jbr\bin`). Remember the two passwords you type. Losing this file is recoverable (Play lets you reset the upload key) but painful; never commit it (`*.jks` is gitignored).

### ANDROID_KEYSTORE_BASE64 (Windows PowerShell)
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```
Paste the clipboard into the secret value (one long line, no line breaks). macOS/Linux: `base64 -w0 upload-keystore.jks`.

### ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD
The store password and key password you chose in `keytool`, and the `-alias` value (`upload` in the example). Check the alias with `keytool -list -keystore upload-keystore.jks`.

### GOOGLE_SERVICES_JSON
Firebase Console > Project settings > Your apps > add Android app with package `com.planchecked.vuonnha` > download `google-services.json`. Add the SHA-1 of the upload key and (after the first Play upload) the Play app-signing key under "SHA certificate fingerprints", then re-download. Open the file in a text editor and paste **the whole JSON** as the secret value. Enable Cloud Messaging in the Firebase project (the FCM sender on the Supabase side is not built yet).

## Local equivalents
- `app/env/prod.json` (copy of `env/example.json`; `dev.json`, `prod.json` and `ci.json` are gitignored) replaces the two Supabase secrets.
- `app/android/key.properties` replaces the four signing secrets:
  ```
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=../../upload-keystore.jks
  ```
  `storeFile` is resolved relative to `app/android/app/`. In CI the keystore is written to `app/android/app/release.keystore` and `storeFile=release.keystore`.

## Safety notes
- Secrets are not exposed to pull requests from forks and the workflow only runs on tags / manual dispatch. The job deletes `env/ci.json`, `key.properties`, the keystore and `google-services.json` at the end.
- Rotate `SUPABASE_ANON_KEY` only together with a new app release (old builds stop working).
- The Anthropic key (`ANTHROPIC_API_KEY`) is **not** a GitHub secret; it lives only in Supabase secrets (`supabase secrets set ...`).
