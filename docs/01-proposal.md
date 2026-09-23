# Proposal

## The problem, in one sentence
The current LMS interface requires too many clicks to find pending tasks across different subjects, and lacks automated scheduling to help students balance heavy project loads.

## Who it is for
University students juggling multiple complex courses, coding projects, and tight deadlines who currently have to manually check each course page on the default Canvas web instance and copy deadlines into disorganized paper planners or basic notes apps.

## Core features
1. **OAuth 2.0 Canvas Authentication:** Users authenticate directly through the university's Canvas OAuth 2.0 web flow via an embedded WebView handshake. The client application never handles or stores raw credentials; the acquired access token is securely persisted in `shared_preferences`.
2. **Unified Master Feed:** A single, chronologically sorted feed of active tasks across all enrolled courses, equipped with course-based filter chips, sorting sheets (by due date, course, or points), and status tags (overdue, due soon, upcoming).
3. **AI Assistant Chat:** A conversational chat interface powered by Gemini (`google_generative_ai`) allowing students to query course materials, upcoming deliverables, and grade summaries in natural language.
4. **Course Hub & Submissions:** A dedicated course breakdown organizing subjects into sequential Modules, Announcements, Grade breakdowns, and an in-app assignment submission overlay (supporting text entries and file attachments).

## Out of scope, and why
- **Node.js/MongoDB Database Backend:** Out of scope because setting up a dedicated database layer introduces redundant infrastructure and synchronization overhead. The Canvas LMS REST API serves as the definitive source of truth, complemented by local client caching.
- **Interactive Drag-and-Drop Study Planner:** Scoped as a stretch goal. While task milestone breakdown logic is pre-designed, a fully interactive drag-and-drop daily reordering board requires complex gesture state management that risks delaying the primary MVP deliverables.

## Data the app remembers, and where it is saved
The application relies on a local-first caching strategy via `shared_preferences`:
- **User Session & Preferences:** Canvas OAuth 2.0 Access Token, Student Profile metadata (name, initials, email), Theme Preference (`light` or `dark`), and the simulated Offline Mode status.
- **Cached LMS Data (Offline Fallback):** Cross-course assignments, sequential modules, announcements, and grade snapshots stored as JSON-encoded strings to ensure complete app navigability when disconnected or during API sync interruptions.

## Risks
- **CORS Policies & Web API Throttling:** Running a Flutter web build against the Canvas REST API risks browser-level CORS policy blocks during external evaluation.
  * *Mitigation:* A multi-tier defense: (1) Primary development and testing on native/desktop targets to bypass browser CORS entirely, (2) an optional lightweight pass-through proxy deployed on Vercel or Render if web deployment requires header rewriting, and (3) an embedded Offline/Demo Mode toggle that instantly loads pre-structured local data.
- **LLM Context Constraints & Data Hallucination:** Injecting multi-course syllabi into a model prompt risks exceeding token limits and producing inaccurate deadlines.
  * *Mitigation:* A structured prompt builder that sanitizes and injects only task payloads due within a strict rolling 7-day window.

## Changes since the last version

*September 23, 2026*
- **Authentication Realignment:** Replaced the proposed manual API token text field with the standard Canvas OAuth 2.0 web flow to align with the high-fidelity mockups and eliminate raw token handling.
- **CORS Mitigation Strategy Expanded:** Added architectural provisions for a serverless proxy deployed on Render or Vercel to support the deployed Flutter web build alongside the offline toggle.
- **Foundation & Dependency Stabilization:** Upgraded navigation and architecture to `go_router` and `provider`, replaced deprecated Flutter ColorScheme properties with Material 3 surface guidelines, and transitioned to native Flutter Material iconography to guarantee long-term SDK compatibility.

*September 20, 2026*
- **Architecture Pivot:** Shifted from a proposed Node.js/React stack with MongoDB to a local-first Flutter client.
- **Storage Decision:** Swapped MongoDB for `shared_preferences`. User data is private and doesn't need to be shared, so a cloud database is redundant.
- **Scope Reduction:** Moved the automated drag-and-drop study planner to stretch goals after re-scoring the feature against realistic Flutter development speeds.