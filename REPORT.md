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

## Week N (date to date)

**Done this week**
-

**In progress**
-

**Blocked or stuck on**
-

**Decisions made, and why**
-

**Hours spent, roughly:**

**Next week I will:**
-

---
