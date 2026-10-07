# Velo: Your Canvas Co-pilot - Documentation

## 1. Overview
Velo is a distraction-free, local-first client for the Canvas LMS designed to help university students manage heavy project workloads.
It consolidates every unsubmitted task across all subjects into a single, deadline-sorted feed, lets students read course content and submit work without leaving the app, breaks assignments into daily milestones in a Planner, and features a conversational AI Assistant that answers from the student's real Canvas data.

As of Week 3 the app is finished and published on the web, so it no longer has to be cloned and built to be used.

## 2. Setup and installation
There is nothing to clone or install. Velo is deployed on Vercel, and every step to get into the app from nothing is:

- Open either live link in a browser:
  - Landing page: [velo-landing-page-delta.vercel.app](https://velo-landing-page-delta.vercel.app/), which introduces Velo and leads into the app.
  - The app itself: [velo-canvas-copilot.vercel.app](https://velo-canvas-copilot.vercel.app/), which opens straight on the sign-in screen.
- What you need:
  - A modern browser on a phone, tablet or desktop.
  - A Holy Angel University Canvas account, because the live app is connected to `hau.instructure.com`.
- Get a Canvas access token (the sign-in screen has a "How do I find my access token?" guide with the same steps):
  1. Open Canvas in your browser and log in.
  2. Go to **Account > Settings**.
  3. Scroll to **Approved Integrations** and click **+ New Access Token**.
  4. Type "Velo" as the purpose, set an expiration date, and click **Generate Token**.
  5. Copy the token right away. Canvas only shows it once.
- Configuration:
  None. There is no `.env` file to create and no API key to supply. The Canvas token is pasted at sign-in and kept only on your device, and the AI key stays on the server.

## 3. How to run it
Open the [live app](https://velo-canvas-copilot.vercel.app/), paste your Canvas access token into the field on the sign-in screen, and tap **Connect to Canvas**.

Velo checks the token against Canvas and then opens the To do feed. The next time you open the link you are taken straight to To do, because the token is remembered on that device until you log out.

To install it like an app, use your browser's **Add to Home Screen** (phone) or **Install** (desktop) option. Velo is a PWA, so it then opens in its own window with its own icon.

## 4. Features and usage
- Sign in (Login Screen): Paste a Canvas access token and tap "Connect to Canvas". The token is verified against Canvas before it is saved, and it never leaves the device except to reach Canvas. A built-in guide explains how to generate one.
- Global Navigation (App Shell): On a phone, a bottom bar switches between Courses, Campus++, AI Assistant and To do, and a side drawer adds the Planner, Inbox and Account & Settings. On tablet and desktop widths the side drawer is pinned open.
- To do: One feed of every unsubmitted task across all courses, sorted by deadline, with a summary of what is overdue, due today and due this week. Each card shows its course image.
- Courses: Every active course with its Canvas image or colour and its count of active tasks. Each course opens to its Announcements, Modules, Grades and Assignments.
- Assignments and submissions: Assignment instructions from Canvas, and real submissions as a file upload, a text entry or a website URL. The comment thread with the instructor can be read and posted to.
- Planner: Breaks assignments into daily milestones. Auto-Plan asks the AI to spread upcoming work across the days before each deadline, and every step stays editable.
- AI Assistant: A chat powered by Groq that answers from live Canvas data (tasks, grades, announcements, messages and assignment details). Replies link straight to the task or thread in the app.
- Inbox: Canvas conversations and course announcements together. Read, reply, compose, archive and delete, with an unread badge in the navigation.
- Offline mode: Everything already opened is cached on the device. Screens load from the cache first and refresh in the background, and offline mode shows saved data with the last sync time.
- Account & Settings: The Canvas profile and bio, light and dark themes, deadline reminders, and log out, which clears everything saved on the device.

## 5. Project structure
```text
Velo-A-better-canvas/
├── .github/
│   └── workflows/
│       └── deploy-web.yml
├── api/
│   └── groq.js
├── docs/
│   ├── assets/
│   ├── documentation/
│   │   ├── 01-documentation-week-1.md
│   │   ├── 02-documentation-week-2.md
│   │   └── 03-documentation-week3.md
│   ├── presentation/
│   │   └── README.md
│   ├── 01-proposal.md
│   ├── 02-mockup.md
│   ├── 03-design-system.md
│   ├── 04-weekly-reports.md
│   ├── 05-demo-video.md
│   ├── 06-security-and-privacy.md
│   └── README.md
├── journal/
│   ├── week-1.md
│   ├── week-2.md
│   └── week-3.md
├── lib/
│   ├── components/
│   │   ├── planner/
│   │   │   ├── day_sheet.dart
│   │   │   ├── milestone_editor_sheet.dart
│   │   │   └── todays_focus_card.dart
│   │   ├── app_shell.dart
│   │   ├── bottom_nav.dart
│   │   ├── chat_bubble.dart
│   │   ├── course_image.dart
│   │   ├── error_dialog.dart
│   │   ├── offline_banner.dart
│   │   ├── reconnect_prompt.dart
│   │   ├── side_drawer.dart
│   │   ├── submission_comments.dart
│   │   ├── submission_sheet.dart
│   │   └── task_card.dart
│   ├── models/
│   │   ├── course.dart
│   │   ├── milestone.dart
│   │   └── task.dart
│   ├── screens/
│   │   ├── account_screen.dart
│   │   ├── ai_assistant_screen.dart
│   │   ├── compose_message_screen.dart
│   │   ├── conversation_detail_screen.dart
│   │   ├── course_announcements_screen.dart
│   │   ├── course_assignments_screen.dart
│   │   ├── course_detail_screen.dart
│   │   ├── course_grades_screen.dart
│   │   ├── course_modules_screen.dart
│   │   ├── courses_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── inbox_screen.dart
│   │   ├── login_screen.dart
│   │   ├── module_item_detail_screen.dart
│   │   ├── planner_screen.dart
│   │   └── task_detail_screen.dart
│   ├── services/
│   │   ├── canvas_refresh.dart
│   │   ├── canvas_service.dart
│   │   ├── error_text.dart
│   │   ├── groq_service.dart
│   │   ├── planner_store.dart
│   │   └── safe_launch.dart
│   ├── state/
│   │   └── app_state.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── main.dart
├── test/
│   ├── bottom_nav_test.dart
│   ├── canvas_cache_test.dart
│   ├── chat_bubble_test.dart
│   ├── hardening_test.dart
│   ├── planner_store_test.dart
│   ├── reconnect_test.dart
│   ├── side_drawer_test.dart
│   └── widget_test.dart
├── web/
│   ├── icons/
│   ├── favicon.png
│   ├── index.html
│   └── manifest.json
├── .env.example
├── .gitignore
├── AI-USAGE.md
├── analysis_options.yaml
├── LICENSE
├── pubspec.lock
├── pubspec.yaml
├── README.md
├── REPORT.md
├── vercel.json
└── vercel_build.sh
```

## 6. Screenshots

| Log in | To do | Courses |
| --- | --- | --- |
| <img src="/docs/assets/login-final.png" alt="Log in" width="250"> | <img src="/docs/assets/todo-final.png" alt="To do" width="250"> | <img src="/docs/assets/courses-final.png" alt="Courses" width="250"> |

| ADET course | Announcements | Modules |
| --- | --- | --- |
| <img src="/docs/assets/adet-final.png" alt="ADET course" width="250"> | <img src="/docs/assets/announcements-final.png" alt="Announcements" width="250"> | <img src="/docs/assets/modules-final.png" alt="Modules" width="250"> |

| Grades | Assignments | Planner |
| --- | --- | --- |
| <img src="/docs/assets/grades-final.png" alt="Grades" width="250"> | <img src="/docs/assets/assignments-final.png" alt="Assignments" width="250"> | <img src="/docs/assets/planner-final.png" alt="Planner" width="250"> |

| AI Assistant | Inbox | Side Drawer |
| --- | --- | --- |
| <img src="/docs/assets/aiassisstant-final.png" alt="AI Assistant" width="250"> | <img src="/docs/assets/inbox-final.png" alt="Inbox" width="250"> | <img src="/docs/assets/sidedrawer-final.png" alt="Side Drawer" width="250"> |

| Account & Settings |
| --- |
| <img src="/docs/assets/accountandsettings-final.png" alt="Account and Settings" width="250"> |

## 7. Known issues and next steps
**Known Issues:**
- Sign-in uses a manually generated Canvas access token, not Canvas OAuth.
- The live app is connected to Holy Angel University's Canvas, so it only works with a HAU Canvas account.
- Media-recording submissions open in Canvas; they are not sent from the app.
- A submission carries one file.
- Deadline reminders work on mobile builds, not on the web build.

**Next Steps:**
- Replace manual tokens with Canvas OAuth sign-in if a developer key becomes available.
- Add media-recording and multi-file submissions.
- Bring deadline reminders to the web build.

## AI usage
This repository includes an `AI-USAGE.md` file detailing the prompt engineering, generative models used, and implementation context utilized during the development of this application.
