# Proposal

## The problem, in one sentence
The current LMS interface requires too many clicks to find pending tasks across different subjects, and lacks automated scheduling to help students balance heavy project loads.

## Who it is for
University students juggling multiple complex courses, coding projects, and tight deadlines who currently have to manually check each course page on the default Canvas web instance and copy deadlines into disorganized paper planners or basic notes apps.

## Core features
1. **Secure Token Auth:** Users log in using their Canvas API token, secured via `shared_preferences`.
2. **Unified Master Feed:** A single, chronologically sorted feed of active tasks across all enrolled courses, built with `FutureBuilder` and `ListView.builder`.
3. **AI Assistant Chat:** A conversational interface using the `google_generative_ai` package (Gemini) that allows students to query their specific course context.
4. **Course List & Details:** A dedicated list of enrolled courses with `ExpansionTile` breakdowns of specific modules and announcements.

## Out of scope, and why
- **Node.js/MongoDB Backend:** Out of scope because setting up a cloud database adds backend complexity and hosting costs for zero user benefit in a showcase app. The official Canvas API acts as the definitive backend, and a local-first architecture is much more efficient.
- **Interactive Drag & Drop Planner:** Moved to a stretch goal. Creating a unified feed and a functional AI chat interface will consume the ~23-hour MVP budget. A complex drag-and-drop planner requires advanced state management that risks breaking the core app before the deadline.

## Data the app remembers, and where it is saved
Because this is a personal planner and data is not shared between users, the app relies on a local-first caching strategy:
- **User Profile:** Canvas API Token, Student Name, and Theme Preference are saved directly in `shared_preferences`.
- **Cached Tasks (Fallback):** Task Name, Due Date, Course ID, and Status are saved in `shared_preferences` as a JSON-encoded `List<String>` to act as an offline fallback if the Canvas API is unreachable.

## Risks
- **CORS Policies / Rate Limiting:** Building Flutter web apps introduces the risk of CORS policies blocking Canvas API calls in the browser during grading. 
  * *Mitigation:* A "Demo Mode" toggle will be built to forcefully bypass the API and load local dummy JSON data.
- **LLM Context Constraints & Data Hallucination:** Pushing massive amounts of syllabus text into an LLM prompt might exceed token limits or cause it to invent fake deadlines.
  * *Mitigation:* A strict prompt template will be implemented to only feed the LLM the exact, truncated JSON for assignments due in the next 7 days.

## Changes since the last version

*September 20, 2026*
- **Architecture Pivot:** Shifted from a proposed Node.js/React stack with MongoDB to a local-first Flutter client. Realized maintaining a separate backend proxy would cause me to miss the final deadline.
- **Storage Decision:** Swapped MongoDB for `shared_preferences`. User data is private and doesn't need to be shared, so a cloud database is redundant.
- **Scope Reduction:** Moved the automated drag-and-drop study planner to stretch goals after re-scoring the feature against realistic Flutter development speeds (estimated ~15 hours just for the feed and chat UI).
