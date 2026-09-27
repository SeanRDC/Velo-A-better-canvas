# Security and privacy

**Last checked:** 2026-09-27

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| User session and Canvas API token | on the device (`shared_preferences`) | only that user |
| Cached Canvas data (assignments, grades, modules, inbox) | on the device (`shared_preferences`) | only that user |
| App preferences (theme, offline mode toggle) | on the device (`shared_preferences`) | only that user |

## Secrets

- Values my app needs at run time: `CANVAS_API_TOKEN`, `CANVAS_BASE_URL`, `GEMINI_API_KEY`
- Where they live locally: `.env`, which is git-ignored
- Where the deploy workflow gets them: repository secrets (Settings > Secrets
  and variables > Actions; the walkthrough is on page 12 of
  `content/extending-your-app/` in your workspace)
- Anything my deployed web build carries that a visitor could read, and why that
  is acceptable: The Flutter web build inherently bundles the injected environment variables (`GEMINI_API_KEY` and `CANVAS_API_TOKEN`) into the compiled client code because this MVP communicates directly with the APIs. This is acceptable for a local-first academic prototype, though a production release would route these calls through a secure backend proxy to obscure the keys.

## What protects the data on the service side

- No third-party database (like Firestore or Supabase) is used. 
- Nothing leaves the device to a developer-owned backend. All data requests and security protocols are handled directly between the local client and the official Canvas LMS infrastructure, protected by Canvas's own OAuth 2.0 and API security measures.

## Checklist

- [x] `.env` (or `env.json`) is in `.gitignore`, and `.env.example` is committed
- [x] `git log -p | grep -i "api_key\|secret\|password\|token"` finds nothing real
- [x] No service account file, keystore or `service_role` key anywhere in the repo
- [x] Security rules or RLS policies written and tested, not left open *(N/A - relies strictly on Canvas LMS security)*
- [x] No real personal data in sample data, screenshots or the video
- [x] No course or university credentials anywhere
- [x] Anyone whose data appears in a test was asked first
