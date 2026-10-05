# AI usage

## Contents

- [1. How I used AI](#1-how-i-used-ai)
- [2. Where the AI got it wrong](#2-where-the-ai-got-it-wrong)
- [3. Who wrote what](#3-who-wrote-what)

---

## 1. How I used AI

At least six entries. One per real use. Every entry needs a commit link.

| # | Date | Entry | Commit |
| --- | --- | --- | --- |
| 1 | 2026-09-25 | Retry logic for AI assistant rate limits | [`3e6c98b`](https://github.com/SeanRDC/Velo-A-better-canvas/commit/3e6c98b) |
| 2 | 2026-09-26 | Announcement attachments | [`e88b9c9`](https://github.com/SeanRDC/Velo-A-better-canvas/commit/e88b9c9) |
| 3 | 2026-09-26 | Rich HTML announcements | [`6ef1e7d`](https://github.com/SeanRDC/Velo-A-better-canvas/commit/6ef1e7d) |
| 4 | 2026-09-27 | Inbox archive and delete | [`798e0a2`](https://github.com/SeanRDC/Velo-A-better-canvas/commit/798e0a2) |
| 5 | 2026-09-28 | Canvas context for the AI assistant | [`a95010a`](https://github.com/SeanRDC/Velo-A-better-canvas/commit/a95010a) |
| 6 | 2026-10-03 | Vercel build script | [`056f63d`](https://github.com/SeanRDC/Velo-A-better-canvas/commit/056f63d) |

### 2026-09-25 - Retry logic for AI assistant rate limits

- **Tool:** TODO
- **What I asked for:** A way to stop the assistant from failing outright when Gemini returns a 429 rate-limit error.
- **What it gave back:** A retry loop with exponential backoff and random jitter around `_chat.sendMessage`, up to 4 attempts.
- **What I kept, what I changed, and why:** Kept the retry loop. I added the `_isLoading` guard so a second message cannot be sent mid-request, removed my diagnostic prints, and replaced the raw exception text with a plain error message so users never see a stack trace.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/3e6c98b

### 2026-09-26 - Announcement attachments

- **Tool:** TODO
- **What I asked for:** How to read the `attachments` array in the Canvas announcement payload and let students open the files.
- **What it gave back:** A `_downloadAttachment` helper using `url_launcher`, a `_formatFileSize` helper, and a tappable attachment row.
- **What I kept, what I changed, and why:** Kept both helpers. I styled the attachment rows to match my existing card design and added the paperclip icon on the list view so students can see which announcements have files before opening them.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/e88b9c9

### 2026-09-26 - Rich HTML announcements

- **Tool:** TODO
- **What I asked for:** A way to show Canvas announcement bodies with their real formatting and clickable links instead of stripped plain text.
- **What it gave back:** The `flutter_html` package with an `Html` widget, a style map, and an `onLinkTap` handler.
- **What I kept, what I changed, and why:** Kept the approach. I kept my `_stripHtml` function for the list preview snippets, renamed `_downloadAttachment` to `_launchLink` so body links and attachments share one opener, and set the styles from my theme colors.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/6ef1e7d

### 2026-09-27 - Inbox archive and delete

- **Tool:** TODO
- **What I asked for:** The Canvas API calls for archiving and deleting an inbox conversation.
- **What it gave back:** `archiveConversation` and `deleteConversation` methods using `PUT` and `DELETE` on `/api/v1/conversations/:id`.
- **What I kept, what I changed, and why:** Kept the endpoints. I added the offline check at the top of both so they throw a clear message instead of failing silently, matching how my other write methods behave.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/798e0a2

### 2026-09-28 - Canvas context for the AI assistant

- **Tool:** TODO
- **What I asked for:** A way to give the assistant the student's real grades and pending tasks so it stops answering generically.
- **What it gave back:** A `buildSecureAiContext` method that loops over every course and builds one text block of grades and pending assignments for the system prompt.
- **What I kept, what I changed, and why:** Kept the string-building idea and the per-course `try/catch` so one failing course does not break the rest. It reuses my existing `fetchGradesForCourse` and `fetchAssignmentsForCourse` methods instead of new API calls.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/a95010a

### 2026-10-03 - Vercel build script

- **Tool:** TODO
- **What I asked for:** How to deploy a Flutter web build on Vercel, which has no Flutter SDK installed.
- **What it gave back:** A `vercel_build.sh` that clones the stable Flutter SDK, adds it to `PATH`, and runs `flutter build web --release`.
- **What I kept, what I changed, and why:** Kept the SDK steps. I wrote the `.env` lines so the Groq key and Canvas URL come from Vercel's environment variables, and left `CANVAS_API_TOKEN` empty because each student enters their own token at login.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/056f63d

---

## 2. Where the AI got it wrong

Three cases. Be specific. If you write that the AI was never wrong, this section
scores zero.

### Case 1 - Out of date: recommended an unmaintained package

- **What it gave me:** `flutter_html: ^3.0.0` as the HTML renderer.
- **What was wrong with it:** The package has not been updated for the current Dart HTML parser, so it conflicted with the rest of my dependencies.
- **What I did instead:** Replaced it with `flutter_widget_from_html`, which is still maintained, and rewrote the rendering block for that package.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/bec0060

### Case 2 - Wrong: request body Canvas ignores

- **What it gave me:** A `PUT` with a form body of `{'workflow_state': 'archived'}`.
- **What was wrong with it:** Canvas expects `workflow_state` nested inside a `conversation` object, so the request went through but nothing was archived or marked as read.
- **What I did instead:** Sent JSON as `{'conversation': {'workflow_state': ...}}` with a `Content-Type: application/json` header, applied the same fix to `markConversationAsRead`, and added the status code to the error message.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/1ea52af

### Case 3 - Worse than what I did instead: one huge prompt on every chat

- **What it gave me:** A single method that loads everything into the system prompt up front.
- **What was wrong with it:** It sent every course's data on every chat, even for a simple question, which burned through the token quota. The pending-tasks block was also duplicated, so assignments were fetched and written twice.
- **What I did instead:** Split it into three small methods (`buildTasksContext`, `buildGradesContext`, `buildAnnouncementsContext`) and switched to function calling so the model only requests the one it needs.
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/b605e1b

---

## 3. Who wrote what

At least a fifth of this project is code you wrote yourself. Name it, and explain
it in your own words.

> Group projects: give each member their own heading below, and use your GitHub
> handle as the heading. You are graded on your own section.

### Written by me

#### App theme

- **File:** `lib/theme/app_theme.dart`
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/6cef82f
- **What it does and why it is built this way:** Defines the light and dark `ThemeData` for the whole app. Both themes share one private `_primary` color and the same structure, so every screen reads colors from `Theme.of(context)` instead of hardcoding them, and dark mode works everywhere for free.

#### Bottom navigation bar

- **File:** `lib/components/bottom_nav.dart`
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/2d07ee3
- **What it does and why it is built this way:** The persistent bottom bar with the Courses, AI Assistant and Dashboard tabs. One `_buildTab` method builds all three so the active styling lives in one place, and it skips `context.go` when the tab is already active to avoid reloading the current screen.

#### Course and task models

- **File:** `lib/models/course.dart`, `lib/models/task.dart`
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/85c6fe3
- **What it does and why it is built this way:** The `Course` model and `Task.fromCanvasJson`, which map raw Canvas JSON into typed objects. Every field has a fallback (`'Unknown Course'`, 0 points, a far-future due date) because Canvas often returns null, and one bad field should not crash the whole list.

#### Unread inbox badge

- **File:** `lib/state/app_state.dart`, `lib/components/side_drawer.dart`
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/6eeb3b1
- **What it does and why it is built this way:** A global `unreadInboxCount` in `AppState` with `updateUnreadInboxCount`, which replaced the hardcoded `3` in the side drawer. It lives in the provider so the drawer badge updates as soon as the inbox screen reports a new count.

#### Offline banner

- **File:** `lib/components/offline_banner.dart`
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/fabd7e4
- **What it does and why it is built this way:** A full-width strip that tells the student they are viewing saved data. It is a stateless widget that only reads the theme, so the app shell can show or hide it on any screen without extra logic.

#### Global app state

- **File:** `lib/state/app_state.dart`
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/5495cc7
- **What it does and why it is built this way:** The global `AppState` for offline mode and theme. It takes `SharedPreferences` in its constructor so saved settings load before the first frame, and every setter saves and then calls `notifyListeners()` so the UI and storage never disagree.

### The AI-written part I understand best

- **File:** `lib/screens/ai_assistant_screen.dart`
- **Commit:** https://github.com/SeanRDC/Velo-A-better-canvas/commit/fe59be1
- **What it does and why we kept it:** The function-calling loop for the assistant. It works in three steps:
  1. It declares three tools to the model (`get_pending_tasks`, `get_course_grades`, `get_recent_announcements`), each with a description so the model knows when to use it.
  2. After sending the user's message, it checks `response.functionCalls`. If the model asked for a tool, it runs the matching `CanvasService` method and sends the result back with `Content.functionResponse`.
  3. It repeats in a `while` loop until the model replies with text instead of another tool call, so one question can pull tasks and grades in the same turn.

  We kept it because the model only pulls Canvas data when the question needs it. The earlier version put every course's data in the system prompt on every message, which is what kept exhausting the token quota (see Case 3). The system prompt also tells the model it does not know the student's deadlines by default, which stops it from inventing them.
