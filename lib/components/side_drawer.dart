// Secondary Navigation and Settings Drawer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
            ),
            accountName: Text(
              'Sean Rhani J. Dela Cruz',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            accountEmail: Text(
              'Canvas Student',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                'SD',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.calendar_month_outlined, color: theme.colorScheme.secondary),
                  title: Text('Planner', style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    // TODO: Route to Planner when built
                  },
                ),
                ListTile(
                  leading: Icon(Icons.inbox_outlined, color: theme.colorScheme.secondary),
                  title: Text('Inbox', style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context); 
                    // TODO: Route to Inbox when built
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                ),
                // Global Theme Toggle
                SwitchListTile(
                  secondary: Icon(
                    appState.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text('Dark Mode', style: theme.textTheme.bodyMedium),
                  value: appState.themeMode == ThemeMode.dark,
                  onChanged: (bool isDark) {
                    appState.setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                // Offline Toggle (Demo Feature)
                SwitchListTile(
                  secondary: Icon(
                    appState.isOffline ? Icons.cloud_off : Icons.cloud_done_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text('Offline Fallback', style: theme.textTheme.bodyMedium),
                  subtitle: Text(
                    'Simulate API failure',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
                  value: appState.isOffline,
                  onChanged: (bool isOffline) {
                    appState.toggleOffline();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.pop(context); // Close the drawer
                  context.go('/'); // Route back to the Login Screen
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}