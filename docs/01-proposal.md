# Proposal

## The problem, in one sentence
The current LMS interface requires too many clicks to find pending tasks across different subjects, and lacks automated scheduling to help students balance heavy project loads.

## Who it is for
University students juggling multiple complex courses, coding projects, and tight deadlines who currently have to manually check each course page on the default Canvas web instance and copy deadlines into disorganized paper planners or basic notes apps.

## Core features
1. **Canvas Access Token Sign-in:** Users sign in by pasting a personal access token generated in their own Canvas settings. The token is verified against Canvas before it is saved, the app never handles a password, and the token is persisted only on the device in `shared_preferences`.
2. **Unified To do Feed:** A single, deadline-sorted feed of every unsubmitted task across all enrolled courses, with a summary of what is overdue, due today and due this week, and the course image on every card.
3. **AI Assistant Chat:** A conversational chat interface powered by Groq with function calling, allowing students to ask about pending tasks, grades, announcements, inbox messages and assignment details in natural language. Replies link straight to the task or thread in the app.
4. **Course Hub & Submissions:** A dedicated course breakdown organizing subjects into Modules, Announcements, Grades and Assignments, with real in-app submissions (file upload, text entry or website URL) and the submission comment thread.
5. **Planner with AI Auto-Plan:** Breaks assignments into daily milestones. Auto-Plan asks the AI to spread upcoming work across the days before each deadline, and every milestone stays editable.
6. **Inbox:** Canvas conversations and course announcements together, with read, reply, compose, archive and delete, and an unread badge in the navigation.

## Out of scope, and why
- **Node.js/MongoDB Database Backend:** Out of scope because setting up a dedicated database layer introduces redundant infrastructure and synchronization overhead. The Canvas LMS REST API serves as the definitive source of truth, complemented by local client caching.
- **Canvas OAuth 2.0 Sign-in:** Out of scope because the OAuth flow needs a developer key issued by the school's Canvas administrator. Sign-in uses a token the student generates themselves instead.
- **Drag-and-Drop Reordering in the Planner:** The Planner itself moved from a stretch goal into scope, but milestones are edited through a sheet rather than dragged, because gesture-based reordering was not needed to plan a week.
- **Media-Recording and Multi-File Submissions:** A submission carries one file, and media recordings open in Canvas. Both need upload flows beyond what the three supported submission types required.
- **Deadline Reminders on the Web Build:** Reminders are scheduled local notifications, which work on mobile builds but not in the browser.

## Data the app remembers, and where it is saved
The application relies on a local-first caching strategy via `shared_preferences` (browser local storage on the web build). Velo has no database or backend of its own:
- **User Session & Preferences:** The Canvas access token, Theme Preference (`light` or `dark`), the Offline Mode status, deadline reminder settings, and the last sync time.
- **Cached LMS Data (Offline Fallback):** The Canvas profile, courses with their images and colours, assignments, submissions and their comments, grades, modules, announcements and inbox conversations, stored as JSON-encoded strings so screens load from the cache first and stay navigable when disconnected.
- **Study Plans:** The Planner's plans and milestones.
- **Not saved:** The AI Assistant conversation is held in memory only. Logging out removes the token, all cached Canvas data and saved study plans.

## Risks
- **CORS Policies on the Web Build:** Running a Flutter web build against the Canvas REST API is blocked by the browser's CORS policy.
  * *Mitigation:* The app is hosted on Vercel, whose rewrites pass Canvas API and image requests through to Canvas. Offline mode loads the data already cached on the device if Canvas cannot be reached.
- **LLM Rate Limits & Data Hallucination:** Injecting every course's data into one model prompt exceeded free-tier rate and token limits and risks inaccurate deadlines.
  * *Mitigation:* The assistant uses function calling, so the model requests only the Canvas data it needs for each question, and a short client-side cooldown spaces out messages.
- **Exposed AI Key in a Web Build:** Anything bundled into a web build can be read by a visitor, including an API key.
  * *Mitigation:* The Groq key lives only in a Vercel serverless function (`api/groq.js`), which adds it on the server and only answers callers whose Canvas token is accepted by Canvas.
- **Token Stored in Plain Local Storage:** The Canvas token sits in `shared_preferences`, not encrypted storage.
  * *Mitigation:* The token is only attached to requests for the Canvas host, students are prompted to set an expiration date when generating it, and logging out clears it.

## Changes since the last version

*October 8, 2026*
- **Sign-in Reversed to Access Tokens:** Replaced the planned Canvas OAuth 2.0 web flow with a personal access token, because OAuth needs a developer key from the school's Canvas administrator.
- **AI Provider Changed:** Replaced Gemini (`google_generative_ai`) with Groq and moved from one large prompt to function calling, after the Gemini free tier's limits proved too tight for a chat that reads Canvas data.
- **Planner Moved Into Scope:** The study planner, previously a stretch goal, was built with daily milestones and AI Auto-Plan. Only drag-and-drop reordering stays out of scope.
- **Inbox Added as a Core Feature:** Canvas conversations and announcements are now part of the app.
- **Submissions Made Real:** Assignment submission now sends files, text entries and URLs to Canvas instead of simulating it, and the comment thread was added.
- **Deployment Settled:** The app is deployed on Vercel as an installable PWA, with rewrites as the CORS proxy and a serverless function holding the AI key.

*September 23, 2026*
- **Authentication Realignment:** Replaced the proposed manual API token text field with the standard Canvas OAuth 2.0 web flow to align with the high-fidelity mockups and eliminate raw token handling.
- **CORS Mitigation Strategy Expanded:** Added architectural provisions for a serverless proxy deployed on Render or Vercel to support the deployed Flutter web build alongside the offline toggle.
- **Foundation & Dependency Stabilization:** Upgraded navigation and architecture to `go_router` and `provider`, replaced deprecated Flutter ColorScheme properties with Material 3 surface guidelines, and transitioned to native Flutter Material iconography to guarantee long-term SDK compatibility.

*September 20, 2026*
- **Architecture Pivot:** Shifted from a proposed Node.js/React stack with MongoDB to a local-first Flutter client.
- **Storage Decision:** Swapped MongoDB for `shared_preferences`. User data is private and doesn't need to be shared, so a cloud database is redundant.
- **Scope Reduction:** Moved the automated drag-and-drop study planner to stretch goals after re-scoring the feature against realistic Flutter development speeds.
