# Demo video

**File:** hosted on Google Drive: [Watch the demo video](https://drive.google.com/file/d/1srRAMAWLhorcxRxCmBE96qDclZ4s_ygR/view?usp=sharing)
**Length:** about 10 minutes
**Recorded on:** the web build of Velo in a desktop browser, with VS Code for the code walkthrough

## What it shows

A short list, in order, so a viewer can skip to what they need. Times are approximate.

- 0:00 what Velo is and who it is for: university students whose Canvas deadlines are spread across every course
- 0:20 signing in with a Canvas access token
- 0:30 the To do feed: every unsubmitted task across all courses, sorted by deadline, with course images
- 0:45 Courses, and one course's announcements, modules, grades and assignments
- 0:55 an assignment: instructions from Canvas, the comment thread, and a real submission
- 1:20 the Planner and Auto-Plan, which breaks assignments into daily milestones
- 1:40 the AI Assistant answering from live Canvas data, with links that open tasks in the app
- 1:55 the Inbox, with Canvas messages and announcements together
- 2:00 offline mode, showing saved data and the last sync time
- 2:10 the code: the cached fetch in `lib/services/canvas_service.dart` and the global state in `lib/state/app_state.dart`
- 2:40 the AI segment: how AI was used to build the app, three cases where it was wrong, and the parts written by hand
- 4:50 what is next

The walkthrough follows the main user journey end to end: sign in, see what is due, open the course, read the assignment, submit it, and plan the rest. Deadline reminders only work on a mobile build, so they are not shown in this recording.

More detail on each part is in the [presentation notes](presentation/README.md).

## Getting it into the repo

The video is not committed to this repository. GitHub blocks any file over 100 MB and warns over 50 MB, so the recording is hosted on Google Drive and linked at the top of this page.

## Before you record

- Real data off the screen: no classmates' names, numbers, faces or messages.
- Notifications off.
- Sensible sample data, not "asdf".
- One unbroken take per feature. Say what you are doing while you do it.
