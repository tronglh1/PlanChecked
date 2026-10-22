# Privacy Policy – Vườn Nhà

Version: 2026-10 · Effective: 19 October 2026 · Contact: `<EMAIL_LIÊN_HỆ>`

"Vườn Nhà" (the "app", "we") is a free app that helps you schedule and track plant care at home. This policy explains what data we collect, why, where it is stored, who receives it and what rights you have, in line with Vietnam's Decree 13/2023/ND-CP on personal data protection and Google Play policy.

Data controller and processor: the individual owner of the Vườn Nhà app, reachable at `<EMAIL_LIÊN_HỆ>`.

## 1. Data we collect

| Category | Details | Required? |
|---|---|---|
| Account | Email address (Google sign-in or one-time code sent by email), user ID | Yes |
| Profile | Display name, avatar (optional), language, time zone, experience level, time budget, organic preference, whether the home has children / pets, quiet hours | Display name: yes; rest optional |
| Province-level location | The province/city you pick manually and the derived climate zone (North/Central/South). We do **not** collect GPS or precise location | Yes (seasonal scheduling) |
| Plant projects | Plant type, start date, growing space, sunlight level, care plan, growth milestones | When using the feature |
| Plant photos | Photos you take or choose for check-ins, project covers, plus condition tags and a note (max 200 characters) you enter | Optional |
| Task logs | Tasks done / skipped / snoozed, timestamps, reasons, notes, experience points, badges, streak | When using the feature |
| Household sharing | Household name, members and roles, invite codes, shared activity | Optional |
| Device | Firebase Cloud Messaging push token and platform (Android) | Only if you allow notifications |
| Consent | Record that you accepted the terms, policy and data processing, with version and time | Yes |
| Technical | Minimal server and error logs (IP address, time, error code) created by our infrastructure providers | Automatic |

The app has **no ads**, **no advertising trackers**, we **do not sell personal data**, and we do not collect contacts, GPS location, microphone or financial data.

## 2. Purposes

- Create and protect your account; sign you in.
- Build and remind you of a care plan suited to season, region and growing space.
- Analyse plant photos with AI to estimate growth stage, signs of disease or deficiency and suggest plan adjustments (you always approve changes).
- Compute experience points, badges and streaks.
- Share projects and tasks with household members you invite.
- Send task reminders and household activity notifications.
- Security, abuse prevention (e.g. daily AI call limits) and bug fixing.
- Comply with law.

Legal bases: your consent (recorded at first sign-in), performance of the service you request, and legal obligations. You may withdraw consent at any time (section 8).

## 3. AI processing of photos (Anthropic – Claude API)

When you request analysis of a check-in, the app uploads the (downscaled) photo to our server (Supabase). The server calls the **Claude API of Anthropic PBC** (United States) and sends:

- the plant photo you took;
- the plant and project context needed (plant type, stage, season, climate zone, space, sunlight);
- the condition tags and short note you entered;
- the "children / pets at home" flags, to give safety-aware suggestions.

We do **not** send Anthropic your email, display name, avatar or user ID. The API key lives only on our server, never in the app. Under Anthropic's commercial terms, data sent through the API is not used to train models and may be retained temporarily under Anthropic's own policy (https://www.anthropic.com/legal/privacy). This means your data may be transferred outside Vietnam (United States). We send only what is necessary, and you can skip photo check-ins and still use the rest of the app. AI output is a suggestion, not professional agronomic advice.

## 4. Storage and security

- Data is stored on **Supabase** (PostgreSQL database and file storage), hosted in **Singapore**.
- Photos are in a private bucket, reachable only through short-lived signed URLs. Every table uses row-level security: you can only see your own data and that of the household you belong to.
- Transport uses HTTPS. The offline cache on your phone lives in the app's private storage and is excluded from Android cloud backup.
- Push notifications use **Firebase Cloud Messaging (Google)**; Google sign-in uses Google services; they process data under their own policies.
- One-time-code emails are sent through a transactional email provider we configure.

No system is perfectly secure. If a personal data breach occurs we will notify you and the competent authority as required by law.

## 5. Retention

- Account, project, log and photo data are kept until you delete them or delete your account.
- When you delete your account, your personal data and photos are removed from the database and storage immediately; infrastructure backups (if any) are overwritten within at most 30 days.
- Consent records and minimal technical logs may be kept longer where the law requires.
- Push tokens are deleted with the account or when they become invalid.

## 6. Household sharing

When you create or join a household and share a project, other members can see: your display name, avatar, level and points, the shared projects with their check-in photos and tasks, and shared activity (e.g. "A watered the basil"). The household Owner can invite and remove members. You can leave at any time; projects you shared become private. We do not share your data with anyone outside your household.

## 7. Sharing with third parties

We do not sell data. Data is processed only by providers needed to run the app: Supabase (storage, authentication), Anthropic (AI photo analysis, section 3), Google (Google sign-in, Firebase Cloud Messaging), a transactional email provider (OTP codes), and GitHub (source code only, no user data). We may disclose data when a competent authority lawfully requires it.

## 8. Your rights (Article 9, Decree 13/2023/ND-CP)

You may: be informed about processing; consent or refuse; access, view and correct your data; withdraw consent; delete data; restrict processing; object to processing; request a copy of your data; and complain, report, sue and claim damages under the law.

How to exercise them:
- **Edit**: in the app under Profile / Settings.
- **Delete account and all data in the app**: Settings > "Delete account and all data" (two confirmations). Deletion is immediate and irreversible.
- **Delete on the web (without installing the app)**: see the "Account deletion request" page (`delete-account.html`) or email `<EMAIL_LIÊN_HỆ>` from the email address you registered with, subject "Vườn Nhà account deletion". We reply within 72 hours and finish deletion within 30 days at most.
- **Other rights** (access, copy, withdraw consent, restrict, object): email `<EMAIL_LIÊN_HỆ>`; we handle requests within 72 hours after verifying your identity.

## 9. Children

The app is not directed to children under 16. People 16 or older may use it; children under 16 may use it only with consent of a parent or guardian as required by Decree 13/2023/ND-CP. If we learn we collected a child's data without valid consent, we will delete it.

## 10. Changes

For material changes we update the version and effective date above and notify you in the app; we may ask you to consent again.

## 11. Contact

Email: `<EMAIL_LIÊN_HỆ>` (owner of the Vườn Nhà app, Vietnam).
