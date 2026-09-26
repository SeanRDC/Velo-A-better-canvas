// Side Drawer Component
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

// Local mock data mirroring the TypeScript context
const _currentUser = {
  'name': 'Sean Rhani Jarin Dela Cruz',
  'initials': 'SD',
  'program': 'Holy Angel University',
};

const int _unreadInboxCount = 3;

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header — Avatar + Profile
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      _currentUser['initials']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser['name']!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _currentUser['program']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _DrawerTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Planner',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/planner');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerTile(
                    icon: Icons.inbox_outlined,
                    label: 'Inbox',
                    badge: _unreadInboxCount,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/inbox');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Account & Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/account');
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Appearance Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isDark ? 'Dark mode' : 'Light mode',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            context.read<AppState>().setTheme(
                              isDark ? ThemeMode.light : ThemeMode.dark
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.secondary.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  left: isDark ? 22.0 : 2.0,
                                  right: isDark ? 2.0 : 22.0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer — Log Out
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 18, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (badge != null && badge! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}