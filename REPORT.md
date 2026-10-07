# Weekly reports

## Week 1 (September 16, 2026 to September 23, 2026)

**Done this week**
- Translated the TypeScript/React prototype foundation into a native Flutter architecture.
- Configured a Material 3 AppTheme with a strict 5-color palette for both Light and Dark modes.
- Built the LoginScreen UI with a simulated OAuth loading state and a reusable ErrorDialog.
- Implemented the AppShell and BottomNav components for persistent global navigation.
- Fixed widget tests to accommodate the new VeloApp entry point and injected mock preferences.
- Resolved all Flutter SDK deprecation warnings (scaffoldBackgroundColor and .withValues).

**In progress**
- Master Dashboard UI and Assignment Cards.
- Side Drawer for secondary navigation and theme toggling.
- Translating mock JSON data into a Dart data layer.

**Blocked or stuck on**
- Hit a fatal compiler crash because the third-party lucide_icons package attempted to extend IconData, which was recently made a final class in the latest Flutter SDK.
- Encountered linter warnings for deprecated Material 3 tokens (background and .withOpacity()). Both blockers were successfully resolved.

**Decisions made, and why**
- Dropped lucide_icons: Decided to strip out the broken third-party package entirely and rely strictly on native Flutter Material Icons. This guarantees zero-dependency stability and prevents future build crashes.
- OAuth 2.0 over API Tokens: Decided to stick with a standard OAuth 2.0 web flow (via an embedded WebView) rather than a manual token text field to enhance security and perfectly match the high-fidelity mockups.

**Hours spent, roughly:**
- 5 hours

**Next week I will:**
- Build the SideDrawer component and wire up the global Light/Dark mode toggle.
- egin laying the groundwork for live Canvas REST API HTTP requests.

---

## Week 2 (September 23, 2026 to September 27, 2026)

**Done this week**
- Built out the core UI for all app screens, expanding from the initial main screen and mockups completed in Week 1.
- Implemented the foundational Canvas LMS REST API integration.
- Successfully integrated the Gemini generative AI model into the application.

**In progress**
- Actively refining and developing the Master Dashboard screen.
- Laying the structural groundwork for the upcoming Planner hub.

**Blocked or stuck on**
- None at the moment; smooth progress as I am primarily focused on laying out the foundational UI and backend systems.

**Decisions made, and why**
- **Local-First Caching:** Decided to strictly maintain the local-first caching strategy for Canvas payloads to keep the app lightweight and avoid the overhead of a cloud database.
- **Design Refinements:** Applied general design tweaks across the newly built screens to ensure strict adherence to the Material 3 minimalist design system.

**Hours spent, roughly:**
19 hours

**Next week I will:**
- Finish the Dashboard screen and complete any remaining secondary screens.
- Deeply integrate the AI into the app's data layer so that chat responses are accurately tailored to the user's specific courses and deadlines.
- Build the Planner hub and wire up the AI to automatically schedule and plan tasks.
- Finalize the codebase for deployment and deploy the application to the web.

---

## Week 3 (September 28, 2026 to October 6, 2026)

**Done this week**
- Finished the To do screen (formerly the Dashboard): overdue, due today and this week summary, a 14-day window with a divider between pending and upcoming tasks, and course images on every card.
- Built the Planner hub with daily milestones, and connected it to the AI through an Auto-Plan button that schedules upcoming tasks before their deadlines.
- Replaced Gemini with Groq for the AI Assistant and moved it to function calling, with tools for pending tasks, grades, announcements, inbox messages, message threads and assignment details.
- Added chat suggestions, clickable in-app links in AI replies, a typing bubble, and preserved chat history.
- Replaced the simulated login with a real sign-in using a Canvas access token, and synced the Account screen with the live Canvas profile, including bio editing.
- Made assignment submission real: file upload, text entry and website URL now go to Canvas, and the submission comment thread can be read and posted to.
- Pulled course images and colours from Canvas for the Courses list, the course screen and the To do cards.
- Added pull to refresh on every data screen, a last-synced time on the offline banner, and a prompt to go back online when the connection returns.
- Added deadline reminders with adjustable timing for mobile builds.
- Made the layout responsive for tablet and desktop, with a pinned side drawer on larger screens, and added a Campus++ shortcut.
- Deployed the app to the web on Vercel as an installable PWA, with app icons and a proxy for Canvas API requests.
- Redesigned the login, To do, Courses and Inbox screens, and added an opening animation.
- Completed the final documentation: README, AI-USAGE, and the presentation video.

**In progress**
- None. This is the final week, and the planned scope is complete.

**Blocked or stuck on**
- The AI Assistant kept hitting Gemini's free-tier rate limits because every message carried the full course context. Resolved by switching to Groq and to function calling, so the model only requests the data it needs, plus a short client-side cooldown between messages.
- Canvas API calls were blocked by CORS once the app ran in a browser. Resolved by routing them through a Vercel rewrite.
- `setState` was being called after screens were closed, which threw errors during slow network calls. Resolved by adding `mounted` checks across the data screens.
- The submit button only simulated a submission and never reached Canvas. Resolved by implementing the Canvas submission and file upload endpoints.

**Decisions made, and why**
- **Groq over Gemini:** Switched AI providers because the Gemini free tier's rate and token limits were too tight for a chat that reads Canvas data.
- **Function calling over one large prompt:** Split the Canvas context into small tools so each request stays small and the answers come from current data.
- **Access token over OAuth 2.0:** Reversed the Week 1 decision. Canvas OAuth needs a developer key issued by the school's Canvas administrator, so sign-in uses a token the student generates in their own Canvas settings.
- **Vercel for hosting:** Chosen because its rewrites can proxy Canvas requests, which the browser would otherwise block.
- **Course images on cards:** Replaced the date block on To do cards with the course image so courses are easy to tell apart, and moved the date into the line below.

**Hours spent, roughly:**

**Further more, I will:**
- Replace manual tokens with Canvas OAuth sign-in if a developer key becomes available.
- Add media-recording and multi-file submissions.
- Bring deadline reminders to the web build.

---
