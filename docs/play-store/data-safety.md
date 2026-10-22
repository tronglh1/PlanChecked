# Google Play – Data safety form answers

Derived from the code in `app/lib` and `supabase/` on branch `mvp` (M8). Re-verify whenever you add an SDK or a new field sent to the server.

## What the code actually sends (evidence)

| Data | Where in code | Destination |
|---|---|---|
| Email, Google account identity | `features/auth` (Supabase Auth: Google OAuth in browser, email OTP) | Supabase Auth (Singapore); Google for OAuth |
| Display name, avatar, lang, timezone, `province_code`, `zone_code`, experience, time budget, organic/children/pets flags, quiet hours | `features/profile` -> table `users`, bucket `avatars` | Supabase |
| Consent rows (`terms`, `privacy`, `nd13`, version `kConsentVersion`) | `profile_repository.recordConsents` -> `consents` | Supabase |
| Plant projects, plans, tasks, task logs, XP, badges | `features/plants|projects|plan|today|gamification` -> Supabase tables; offline copy in local drift DB | Supabase |
| Check-in photos (JPEG, 768 px), tags, note <= 200 chars; project cover photos | `features/checkin`, `projects` -> bucket `checkins`; Edge Function `ai-checkin` | Supabase, then Anthropic Claude API (photo + plant/project context + tags/note + children/pets flags; no email/name/user id) |
| Household name, members, roles, invites, activity | `features/household` | Supabase |
| FCM push token + platform | `today/data/push_service.dart` -> table `push_tokens` (only if `google-services.json` is bundled) | Supabase; Firebase Cloud Messaging (Google) |
| Not present | no analytics SDK, no ads SDK, no Crashlytics/Sentry in `pubspec.yaml`, no GPS/location permission, no contacts, no microphone | - |

Android permissions in the manifest: `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `CAMERA` (live preview on the check-in screen via the `camera` plugin; photos are only taken when the user taps the shutter). The plugin's `RECORD_AUDIO` is removed in the manifest (`tools:node="remove"`), so no microphone. The gallery is reached through the `image_picker` system picker.

## Section 1 – Data collection and security

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS only; cleartext disabled in release) |
| Do you provide a way for users to request that their data be deleted? | **Yes** |
| Account creation methods | Username/other (Google OAuth) and email OTP |
| Delete account URL | `https://<GITHUB_USER>.github.io/<REPO>/delete-account.html` (GitHub Pages; replace after publishing) |
| Data deletion for partial data | Optional: users can delete a project/check-in in the app |

Independent security review: No. Follows Families policy: not applicable (not a kids app).

## Section 2 – Data types

"Shared" means transferred to a third party. Per Play's definition, transfer to a **service provider that processes data on our behalf** (Supabase, Firebase) is not "sharing". Anthropic receives photos only to process our request under API terms, so strictly it is also a processor. **Recommended conservative choice: declare Photos as shared (Anthropic, AI analysis)**; over-declaring is safe, under-declaring risks rejection.

| Play category / type | Collected | Shared | Optional? | Purposes | Notes |
|---|---|---|---|---|---|
| Personal info > **Email address** | Yes | No | Required | Account management, App functionality | Supabase Auth |
| Personal info > **Name** (display name) | Yes | No | Required | App functionality, Account management | Also visible to your household members (in-app, not third parties) |
| Personal info > **User IDs** | Yes | No | Required | App functionality, Account management | Supabase user uuid |
| Location > **Approximate location** | Yes | No | Required | App functionality (seasonal plan) | Province chosen by hand; no GPS permission |
| Photos and videos > **Photos** | Yes | Yes (conservative) -> Anthropic | Optional | App functionality (AI plant analysis) | Avatar, cover and check-in photos; only check-in photos go to Anthropic |
| App activity > **App interactions** | Yes | No | Required | App functionality | Task logs (done/skip/snooze), XP, badges |
| App activity > **Other user-generated content** | Yes | No | Optional | App functionality | Plant notes (<= 200 chars), household name |
| Device or other IDs > **Device or other IDs** | Yes | No | Optional (needs notification permission) | App functionality (push) | FCM token |
| Financial info, Health and fitness, Messages, Contacts, Calendar, Audio, Files, Web browsing | **No** | - | - | - | - |
| App info and performance (crash logs, diagnostics) | **No** (by us) | - | - | - | Add "Crash logs" if you later integrate Crashlytics/Sentry |
| Precise location | **No** | - | - | - | - |

Data processing facts to keep consistent with the privacy policy: not sold, not used for advertising or marketing, no data used for personalised ads; user data encrypted at rest by Supabase; AI provider does not train on API data.

## Other Play Console declarations

- **App access**: all functionality requires sign-in. Provide reviewers a test account (Google test user or an email that receives OTP; consider a fixed Supabase test user and share the steps in App access instructions).
- **Ads**: No ads.
- **Target audience**: 16+ (do not select "children" age groups; avoids the Families policy).
- **Government app / Financial features / Health apps**: No / No / No (plant care is not a health app).
- **News app**: No. **COVID-19**: No.
- **Permissions declarations**: none that need a form (no SMS, call log, background location, all-files access). `RECEIVE_BOOT_COMPLETED` and `POST_NOTIFICATIONS` need no declaration. No exact alarms.
- **Privacy policy URL**: `https://<GITHUB_USER>.github.io/<REPO>/privacy.html`.
- **Photo and Video permissions policy**: not applicable (picker/intents only, no READ_MEDIA_* permissions).
