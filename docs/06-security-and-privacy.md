# Security and privacy

**Last checked:** 2026-09-27

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| User session and Canvas API token | on the device (`shared_preferences`) | only that user |
| Cached Canvas data (assignments, grades, modules, inbox) | on the device (`shared_preferences`) | only that user |
| App preferences (theme, offline mode toggle) | on the device (`shared_preferences`) | only that user |

## Secrets

- Values my app needs at run time: `CANVAS_BASE_URL`, `GROQ_API_KEY`. The Canvas token is never built in: each user pastes their own at login.
- Where they live locally: `.env`, which is git-ignored
- Where the deploy workflow gets them: repository secrets (Settings > Secrets
  and variables > Actions; the walkthrough is on page 12 of
  `content/extending-your-app/` in your workspace)
- Anything my deployed web build carries that a visitor could read, and why that
  is acceptable: The Flutter web build bundles `.env` as an asset, so `GROQ_API_KEY` can be read by any visitor of the deployed site. This is a known, unresolved risk of this prototype: the key should be rotated, given a spend limit, and moved behind a server-side proxy before wider use. No Canvas token is bundled.

## What protects the data on the service side

- No third-party database (like Firestore or Supabase) is used. 
- Nothing is stored on a developer-owned backend. Canvas requests go from the client to the official Canvas LMS (on the web build, through the Vercel `/api` rewrite) and are authorized by the user's own access token.
- The AI assistant and planner send the coursework details needed for a reply (assignments, grades, messages) to Groq.
- The token and cached data sit in plain `shared_preferences` storage, not encrypted storage. Logging out removes the token, all cached Canvas data, saved study plans and the assistant conversation.

## Checklist

- [x] `.env` (or `env.json`) is in `.gitignore`, and `.env.example` is committed
- [x] `git log -p | grep -i "api_key\|secret\|password\|token"` finds nothing real
- [x] No service account file, keystore or `service_role` key anywhere in the repo
- [x] Security rules or RLS policies written and tested, not left open *(N/A - relies strictly on Canvas LMS security)*
- [x] No real personal data in sample data, screenshots or the video
- [x] No course or university credentials anywhere
- [x] Anyone whose data appears in a test was asked first
