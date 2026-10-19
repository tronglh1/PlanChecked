# Content rating notes (IARC questionnaire, Play Console > App content)

Category: **Utility, Productivity, Communication, or other** (not a game, not social/dating).

| Question | Answer | Why |
|---|---|---|
| Violence / blood / gore | No | - |
| Sexual content / nudity | No | - |
| Profanity / crude humor | No | Seed texts are plant guidance only |
| Controlled substances (drugs, alcohol, tobacco) | No | - |
| Gambling / simulated gambling | No | XP and badges have no monetary value, no loot boxes |
| Fear / horror | No | - |
| Does the app let users interact or exchange content with other users? | **Yes, limited** | Household members see shared projects/photos and activity. No free chat, no public profiles, no discovery of strangers; invite-only |
| Does the app share the user's location with other users? | No | Province is not shown to others |
| Does it allow purchases of digital goods? | No | Free, no IAP |
| Does it contain unrestricted web access? | No | - |
| Does it collect personal info? | Yes | Declared in Data safety |

Expected result: Everyone / PEGI 3 / IARC 3+ (the "users interact" flag may add an interaction note, which is normal).

Target audience and content: choose **16 and over** only. Do not tick any child age band (avoids the Families policy and extra reviews). The app does not appeal to children by design (no cartoon characters targeted at kids).

Other declarations:
- Ads: none. Government app: no. Financial features: none. Health: none (plant care).
- AI-generated content: the app shows AI-generated plant suggestions. Play's AI-Generated Content policy applies only to apps that generate content that could be harmful (e.g. chatbots, image generators); here output is restricted to a fixed code vocabulary rendered from our text templates, no free text from the model is shown. Keep an in-app "report/feedback" route (`ai_feedback` table) as evidence for review.
- Safety notes: seed content is not expert-reviewed (`data_status='ai_unverified'`); mark plants verified before launch, especially toxicity flags for homes with children/pets.
