# Velo - your canvas co-pilot

> Velo is a distraction-free, local-first mobile client for the Canvas LMS designed to help university students manage heavy project workloads.

**Live demo:** PS: Will be hosting the website elsewhere (to be posted once finished)
**Demo video:** `docs/demo.mp4` (to be posted once finished)
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University
**Author:** Sean Rhani J. Dela Cruz

This repository lives in the author's own GitHub account and is public on
purpose. There is no `student.json` here and there should not be one: see
`docs/06-security-and-privacy.md` for what a public repo means for secrets and
personal data.

---

## Screenshots

Put two or three real screenshots at phone size in `docs/assets/`, then replace
this paragraph with them:

| Login Screen | Connection Error | Dashboard Placeholder |
| --- | --- | --- |
| ![Login Screen](/docs/assets/OAuth_Screen.png) | ![Error Dialog](/docs/assets/placeholdererror_screen.png) | ![Dashboard](/docs/assets/dashboard_screen.png) |

## What it does

Three to five bullets. What can a user actually do?

- **Secure Authentication:** Logs users in through the university's Canvas OAuth 2.0 web flow, ensuring passwords are never touched or stored.
- **Unified Master Feed:** Consolidates active assignments across all enrolled subjects into a single, chronologically sorted mobile feed (currently in development).
- **AI Assistant:** Provides a conversational interface powered by Gemini to query syllabus details, grades, and upcoming deadlines in natural language.

## Built with

| | |
| --- | --- |
| Framework | Flutter (Dart) |
| State | `provider` |
| Storage | `shared_preferences` (local-first caching and offline fallback) |
| Other packages | `go_router` (persistent navigation), `device_preview` (web-based device testing), `google_generative_ai` (AI Assistant integration) |

## Running it yourself

```bash
flutter pub get
cp .env.example .env
flutter run -d web-server --web-port 8080
```

Then open http://localhost:8080. Requires Flutter 3.44.0 or higher.

### Environment variables

This project reads its configuration from a `.env` file that is **not** in the
repository. Copy `.env.example`, fill in your own values, and never commit the
result.

| Variable | What it is | Where to get one |
| --- | --- | --- |
| `CANVAS_API_TOKEN` | Canvas LMS access token | Generated from your university Canvas portal settings |
| `GEMINI_API_KEY` | Google Gemini AI key | Google AI Studio |

## Privacy and secrets

Required section. Two or three honest sentences:

- Personal Data: Velo is a strictly local-first application. User profiles, Canvas tokens, and cached course tasks are stored entirely on the device using shared_preferences. No personal data is ever sent to a third-party database.
- Secrets: API keys live exclusively in the local .env file. The application relies on Canvas as the definitive backend, meaning data security is handled entirely by the official LMS infrastructure.
- All sample data and screenshots in this repository contain no real personal information.

## Project documentations

| Document | |
| --- | --- |
| [Proposal](docs/01-proposal.md) | the problem, the users, the scope |
| [Mockup and wireframes](docs/02-mockup.md) | what it looks like, and the screen flow |
| [Design system](docs/03-design-system.md) | colors, type, spacing, components |
| [Weekly reports](docs/04-weekly-reports.md) | what happened each week |
| [Demo video](docs/05-demo-video.md) | the recording and what it shows |
| [Security and privacy](docs/06-security-and-privacy.md) | the checklist, filled in |

| Documentation Guide | |
| --- | --- |
| [Documentation](docs/documentation/01-documentation-week-1.md) | View the project documentation guide for week 1 |
| [Documentation](docs/documentation/02-documentation-week-2.md) | View the project documentation guide for week 2 |

## Status and what is next

**What works:** The core Flutter architecture is established. The Material 3 design system is fully implemented (supporting Light and Dark modes). The global routing (go_router), persistent navigation (AppShell and BottomNav), and authentication UI (LoginScreen and ErrorDialog) are completely functional.

**What is half done / Next steps:**

- The Dashboard currently acts as an architectural placeholder.
- The next step is to build the SideDrawer component to wire up the global theme toggle.
- TypeScript mock JSON data needs to be translated into a Dart data layer to populate the assignment feed before hooking up live Canvas REST API requests.

## Credits

- Packages: see pubspec.yaml
- Icons: Flutter native Material Icons (zero-dependency approach)
- Backend: Officially supported Canvas LMS REST API

## AI use

Generative AI was utilized as a collaborative thought partner during development and for debugging strict Material 3 SDK deprecations, and configuring the global routing layout. See AI-USAGE.md for a complete breakdown of prompt engineering and model usage.

## Licence

MIT, see [LICENSE](LICENSE). Change it if you want different terms[done].
