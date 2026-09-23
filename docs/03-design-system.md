# Design system

The visual foundation and reusable components for Velo - A Better Canvas. 

<img src="assets/dsystem-1.png" width="650" alt="Design System 1" /> 
<img src="assets/dsystem-2.png" width="650" alt="Design System 2" /> 
<img src="assets/dsystem-3.png" width="650" alt="Design System 3" /> 
<img src="assets/dsystem-4.png" width="650" alt="Design System 4" /> 
<img src="assets/dsystem-5.png" width="650" alt="Design System 5" />

*(See `assets/design-system.pdf` for the full high-resolution visual breakdown).*

## Palette

**Dark mode:** explicitly supported (Light and Dark).

Instead of generating from a single seed, the application uses a strict 5-color minimalist palette to maintain high contrast and low cognitive load. The primary color is strictly Black/White to match the high-fidelity mockups, while the original slate gray acts as the secondary accent.

```dart
// Core Design System Theme Configuration
class AppTheme {
  static const _accent = Color(0xFF78909C);
  
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,        // High-contrast primary actions
        onPrimary: Colors.white,      // Text on primary buttons
        surface: Color(0xFFFFFFFF),   // Elevated elements / Dialogs
        onSurface: Colors.black,      // Primary Text
        error: Color(0xFFD32F2F),     // High-contrast red for failures
        onError: Colors.white,        // Text on error
        secondary: _accent,           // Slate gray for secondary elements
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Universal backdrop
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,        // High-contrast primary actions
        onPrimary: Colors.black,      
        surface: Color(0xFF1E1E1E),   // Elevated elements / Dialogs
        onSurface: Colors.white,      // Primary Text
        error: Color(0xFFCF6679),     // Adjusted red for dark mode readability
        onError: Colors.black,        
        secondary: _accent,           // Slate gray for secondary elements
      ),
      scaffoldBackgroundColor: const Color(0xFF121212), // Universal backdrop
    );
  }
}
```

## Type scale

```dart
textTheme: const TextTheme(
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
  labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
),
```

| Your style | Flutter slot | Size | Weight | Used for |
| --- | --- | --- | --- | --- |
| type-heading | `headlineSmall` | 24 | Bold | Screen titles, main headers, empty states |
| type-body | `bodyMedium` | 16 | Regular | Standard body text, list items, AI chat bubbles |
| type-caption | `labelSmall` | 12 | Light | Timestamps, subtle hints, metadata labels |

## Spacing

The layout is built on an 8px base unit to ensure rhythmic consistency.

```dart
class AppSpacing {
  static const double tight = 8.0;
  static const double standard = 16.0;
  static const double edge = 24.0;
}
```

- **Base unit:** 8px
- **Screen edge padding:** `AppSpacing.edge` (24px)
- **Gap between related items (icon/text):** `AppSpacing.tight` (8px)
- **Gap between sections/lists:** `AppSpacing.standard` (16px)

## Components

| Component | File | Constructor parameters | Appears on |
| --- | --- | --- | --- |
| **Error Dialog** | `lib/components/error_dialog.dart` | `final String title`, `final String message`, `final VoidCallback onDismiss` | Login Screen, Global API Error Handling |
| **App Shell** | `lib/components/app_shell.dart` | `final String title`, `final String activeTab`, `final Widget child` | Dashboard, Courses, AI Assistant, Inbox |
| **Bottom Nav** | `lib/components/bottom_nav.dart` | `final String activeTab` | App Shell (Global) |
| **Borderless List Tile** | `lib/components/task_list_tile.dart` | `final Task task`, `final VoidCallback onTap` | Dashboard, Course Details |
| **AI Chat Bubble** | `lib/components/chat_bubble.dart` | `final String text`, `final bool isUser` | AI Assistant Tab |

## Changes since the last version

| Element | Prelim said | Now says | Why it changed |
| --- | --- | --- | --- |
| Material 3 Backgrounds | Used `background` and `onBackground` in `ColorScheme` | Removed deprecated tokens; relies on `scaffoldBackgroundColor` | Flutter 3.18+ deprecated `background` properties in favor of unified `surface` mapping to avoid linter warnings and precision loss. |
| Primary Action Color | `#78909C` (Slate) | `Colors.black` (Light) / `Colors.white` (Dark) | Adjusted to perfectly match the high-fidelity Figma mockups, ensuring maximum contrast. Slate gray was shifted to the `secondary` token. |
| Reusable Components | Placeholder component names | Updated to match the actual Flutter modular architecture (`error_dialog.dart`, `app_shell.dart`, `bottom_nav.dart`) | Codebase restructuring to utilize an `AppShell` wrapper for global navigation instead of duplicating AppBars and NavBars on every screen. |
| `color-error` Hex Code | `#FAFAFA` (Light) / `#121212` (Dark) | `#D32F2F` (Light) / `#CF6679` (Dark) | Instructor feedback pointed out an internal contradiction: the original hex codes mapped exactly to the background colors instead of a high-contrast red. |
