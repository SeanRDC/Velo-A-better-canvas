# Velo: Your Canvas Co-pilot

## 1. Overview

Velo is a distraction-free, local-first mobile client for the Canvas LMS designed to help university students manage heavy project workloads. It consolidates active tasks across all subjects into a single, chronologically sorted mobile feed and features a conversational AI Assistant for querying syllabus details and deadlines in natural language.

## 2. Setup and installation

To get the application running from scratch (as of this moment), follow these steps:

- **Environment:** Built with the latest stable Flutter SDK (with strict Material 3 enforcement).
- **Clone the repository:** 
  ```bash
  git clone <your-repository-url>
  cd velo-better-canvas
  ```
- **Install dependencies:**
  ```bash
  flutter pub get
  ```
- **Configuration:** Copy the `.env.example` file to create your own `.env` file in the root directory. You will eventually need to populate this with your billable credentials (these are never committed to version control):
  ```env
  CANVAS_API_TOKEN=your_canvas_api_token_here
  GEMINI_API_KEY=your_gemini_api_key_here
  ```

## 3. How to run it

Launch the app using the local web server with the following command:

```bash
flutter run -d web-server --web-port 8080
```

Once running, open `http://localhost:8080` in your browser. Because the application utilizes the `device_preview` package, you will see it running inside a desktop phone frame displaying the high-contrast "A Better Canvas" Login Screen.

## 4. Features and usage

- **Authentication (Login Screen):** The initial screen presents the application branding and a "Log in with Canvas" button. Tapping this initiates a simulated secure OAuth 2.0 handshake, showing a loading indicator before routing to the main application shell. A secondary text link exists to preview the Material 3 `ErrorDialog` fallback.
- **Global Navigation (App Shell):** Once logged in, the user is placed inside the `AppShell`. This wrapper persists a flush top application bar and a borderless `BottomNav` to seamlessly switch between the Dashboard, AI Assistant, and Courses tabs without losing routing context.
- **Dashboard (My Tasks):** Currently a visual and architectural placeholder demonstrating the successful routing state and persistent layout wrapper post-authentication.

## 5. Project structure

The `lib/` directory is strictly modularized to separate state, UI components, and theming:

- `lib/main.dart`: Core entry point containing `VeloApp`, `go_router` configuration, and `ChangeNotifierProvider` initialization.
- `lib/theme/app_theme.dart`: Defines the strict 5-color high-contrast minimalist palette for both Light and Dark modes.
- `lib/state/app_state.dart`: Global state management handling `shared_preferences` for local data persistence.
- `lib/screens/login_screen.dart`: The initial authentication UI.
- `lib/screens/dashboard_screen.dart`: Master task feed placeholder.
- `lib/components/app_shell.dart`: Persistent global layout wrapper.
- `lib/components/bottom_nav.dart`: Borderless global navigation bar.
- `lib/components/error_dialog.dart`: Reusable modal for API connection failures.

## 6. Screenshots

| Login Screen | Connection Error | Dashboard Placeholder |
| --- | --- | --- |
| ![Login Screen](docs/assets/OAuth_Screen.png) | ![Error Dialog](docs/assets/placeholdererror_screen.png) | ![Dashboard](docs/assets/dashboard_screen.png) |

*(Note: Assets are located in the `docs/assets/` directory.)*

## 7. Known issues and next steps

**Known Issues:** 
- The Master Dashboard UI is currently a structural placeholder.
- The Side Drawer is not yet wired to the menu icon.
- The app utilizes simulated loading delays rather than live data; mock JSON data has not yet been translated into a Dart data layer.

**Next Steps:**
- Build the `SideDrawer` component and wire up the global Light/Dark mode toggle.
- Begin laying the groundwork for live Canvas REST API HTTP requests.

## AI usage

This repository includes an `AI-USAGE.md` file detailing the prompt engineering, generative models used, and implementation context utilized during the development of this application.