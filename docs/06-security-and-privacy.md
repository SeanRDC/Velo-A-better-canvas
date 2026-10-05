# Security and privacy

**Last checked:** 2026-10-06

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| Canvas access token | on the device (`shared_preferences`; browser local storage on the web build) | only that user |
| Cached Canvas data (profile, courses, course images and colours, assignments, submissions and their comments, grades, modules, announcements, inbox) | on the device (`shared_preferences`) | only that user |
| Study plans and milestones from the Planner | on the device (`shared_preferences`) | only that user |
| App preferences (theme, offline mode, reminder settings, last sync time) | on the device (`shared_preferences`) | only that user |
| AI Assistant conversation | in memory only; gone when the app is closed or the user logs out | that user, and Groq while a reply is generated |

Velo has no database or backend of its own. Work the user submits (files, text entries, links) and the comments they post go straight to Canvas and are stored there, not by Velo.

## Secrets

- Values my app needs at run time: `CANVAS_BASE_URL`, `GROQ_API_KEY`. The Canvas token is never built in: each user pastes their own at login, and it is verified against Canvas before it is saved.
- Where they live locally: `.env`, which is git-ignored. `.env.example` is committed with empty values.
- Where the deploy gets them: the published build is deployed on Vercel. `vercel_build.sh` writes `.env` at build time from the Vercel project's environment variables, so no secret is stored in this repository or in GitHub Actions.
- Anything my deployed web build carries that a visitor could read, and why that
  is acceptable: The Flutter web build bundles `.env` as an asset, so `GROQ_API_KEY` can be read by any visitor of the deployed site. This was confirmed on the live site on 2026-10-06. It is a known, unresolved risk of this prototype and is not acceptable for wider use: the key should be rotated, given a spend limit, and moved behind a server-side proxy. No Canvas token is bundled.

## What protects the data on the service side

- No third-party database (like Firestore or Supabase) is used.
- Nothing is stored on a developer-owned backend. Canvas requests go from the client to the official Canvas LMS and are authorized by the user's own access token, so Canvas's own permissions decide what each user can read, submit or comment on.
- On the web build, Canvas requests pass through Vercel rewrites (`/api` and `/images`), because the browser would otherwise block them. The request, including the token header, travels through Vercel on its way to Canvas; Velo does not log or store it.
- The app only attaches the Canvas token to requests for the Canvas host. Links returned by Canvas that point to another host are not followed with the token.
- File submissions are uploaded to the upload location Canvas issues for that submission. Course images load from Canvas's file storage.
- Links inside Canvas content and AI replies only open if they are `http`, `https` or `mailto`.
- The AI Assistant and the Planner's Auto-Plan send the coursework details needed for a reply (assignment names and deadlines, grades, announcements, inbox messages) to Groq. Nothing is sent to Groq unless the user uses those features.
- Submitting, commenting and other changes are blocked while the app is in offline mode.
- The token and cached data sit in plain `shared_preferences` storage, not encrypted storage. Logging out removes the token, all cached Canvas data, saved study plans and the assistant conversation.

## Checklist

- [x] `.env` (or `env.json`) is in `.gitignore`, and `.env.example` is committed
- [x] `git log -p | grep -i "api_key\|secret\|password\|token"` finds nothing real
- [x] No service account file, keystore or `service_role` key anywhere in the repo
- [x] Security rules or RLS policies written and tested, not left open *(N/A - relies strictly on Canvas LMS security)*
- [ ] No real personal data in sample data, screenshots or the video *(the README screenshots show my own name, photo, student email and grades, shared by choice, and the Inbox screenshot shows instructors' names on course announcements)*
- [x] No course or university credentials anywhere
- [x] Anyone whose data appears in a test was asked first
