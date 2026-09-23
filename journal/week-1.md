# Reflection Journal

## Week of: September 23, 2026

## My goal this week
My primary goal was to establish the structural foundation for "Velo: Your Canvas Co-pilot" by translating my existing TypeScript/React prototype into a native Flutter application. I aimed to set up the global design system, state management, routing, and build the initial authentication and navigation UI.

## What I did
I installed the core dependencies (`provider`, `shared_preferences`, `go_router`) and set up a clean, modular directory structure. I translated my CSS variables into a strict Material 3 `AppTheme` utilizing a 5-color palette for both Light and Dark modes. I built the global `AppState` to persist the theme and offline preferences. From there, I built the `LoginScreen` with a simulated OAuth loading state, a reusable `ErrorDialog`, and the persistent `AppShell` wrapper featuring a `BottomNav` bar that hooks into `go_router`. Finally, I updated my widget tests to pass with the new `VeloApp` configuration and injected a mock `shared_preferences` instance for testing.

## What blocked me
I hit several blockers caused by recently deprecated Flutter features. First, the Material 3 `ColorScheme` deprecated the `background` and `onBackground` properties, forcing a pivot to `scaffoldBackgroundColor`. Second, the `.withOpacity()` method was flagged for precision loss, requiring a shift to the new `.withValues(alpha: X)` syntax. The most significant blocker was a fatal build crash caused by the `lucide_icons` package; the latest Flutter SDK made `IconData` a `final` class, preventing the outdated package from extending it.

## What I learned
I learned that the Flutter ecosystem evolves rapidly and everything must be kept up to date. Relying on unmaintained third-party UI packages can unexpectedly break the entire build, making it much safer and more professional to use native, zero-dependency solutions like the built-in Material `Icons`. I also learned the importance of actively reading and resolving SDK deprecation warnings to keep the codebase clean, stable, and ready for production.