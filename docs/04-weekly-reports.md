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
