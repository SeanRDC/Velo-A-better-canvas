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

class SideDrawer extends StatelessWidget {
  final String? activeTab;
  final bool isDesktop;
  final String? desktopTitle;

  const SideDrawer({
    super.key, 
    this.activeTab, 
    this.isDesktop = false,
    this.desktopTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = context.watch<AppState>().unreadInboxCount;

    return Drawer(
      elevation: isDesktop ? 0 : 16,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Render Desktop Title at the top of the Sidebar
            if (isDesktop && desktopTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  desktopTitle!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

            // Header: Avatar + Profile
            Padding(
              padding: EdgeInsets.fromLTRB(24, (isDesktop && desktopTitle != null) ? 16 : 24, 24, 24),
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
                  // Inject Primary Navigation directly into the Drawer on Desktop
                  if (isDesktop) ...[
                    _DrawerTile(
                      icon: Icons.checklist_rtl,
                      label: 'Dashboard',
                      isActive: activeTab == 'tasks',
                      onTap: () {
                        if (!isDesktop) Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerTile(
                      icon: Icons.smart_toy_outlined,
                      label: 'AI Assistant',
                      isActive: activeTab == 'assistant',
                      onTap: () {
                        if (!isDesktop) Navigator.pop(context);
                        context.go('/assistant');
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Courses',
                      isActive: activeTab == 'courses',
                      onTap: () {
                        if (!isDesktop) Navigator.pop(context);
                        context.go('/courses');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Container(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                  ],

                  // Standard Secondary Navigation
                  _DrawerTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Planner',
                    isActive: activeTab == 'planner',
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      context.go('/planner');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerTile(
                    icon: Icons.inbox_outlined,
                    label: 'Inbox',
                    badge: unreadCount,
                    isActive: activeTab == 'inbox',
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      context.go('/inbox');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Account & Settings',
                    isActive: activeTab == 'account',
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
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
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.badge,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 20, 
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
            else if (!isActive)
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}