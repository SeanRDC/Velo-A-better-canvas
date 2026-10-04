// Side Drawer Component
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../services/canvas_service.dart';

class SideDrawer extends StatefulWidget {
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
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  final CanvasService _canvasService = CanvasService();
  Map<String, String> _userProfile = {
    'name': 'Loading...',
    'initials': '-',
    'program': 'Holy Angel University',
    'email': 'Loading...',
    'avatar_url': '',
  };

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _canvasService.fetchUserProfile();
      if (mounted) setState(() => _userProfile = profile);
    } catch (e) {// empt
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = context.watch<AppState>().unreadInboxCount;

    return Drawer(
      elevation: widget.isDesktop ? 0 : 16,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isDesktop && widget.desktopTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  widget.desktopTitle!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

            // Header: Avatar + Profile
            Padding(
              padding: EdgeInsets.fromLTRB(24, (widget.isDesktop && widget.desktopTitle != null) ? 16 : 24, 24, 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: _userProfile['avatar_url']!.isNotEmpty 
                        ? NetworkImage(_userProfile['avatar_url']!) 
                        : null,
                    child: _userProfile['avatar_url']!.isEmpty
                        ? Text(
                            _userProfile['initials']!,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onPrimary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile['name']!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _userProfile['email']!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
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
                  if (widget.isDesktop) ...[
                    _DrawerTile(
                      icon: Icons.checklist_rtl,
                      label: 'Dashboard',
                      isActive: widget.activeTab == 'tasks',
                      onTap: () {
                        if (!widget.isDesktop) Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerTile(
                      icon: Icons.smart_toy_outlined,
                      label: 'AI Assistant',
                      isActive: widget.activeTab == 'assistant',
                      onTap: () {
                        if (!widget.isDesktop) Navigator.pop(context);
                        context.go('/assistant');
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Courses',
                      isActive: widget.activeTab == 'courses',
                      onTap: () {
                        if (!widget.isDesktop) Navigator.pop(context);
                        context.go('/courses');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Container(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                  ],

                  _DrawerTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Planner',
                    isActive: widget.activeTab == 'planner',
                    onTap: () {
                      if (!widget.isDesktop) Navigator.pop(context);
                      context.go('/planner');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerTile(
                    icon: Icons.inbox_outlined,
                    label: 'Inbox',
                    badge: unreadCount,
                    isActive: widget.activeTab == 'inbox',
                    onTap: () {
                      if (!widget.isDesktop) Navigator.pop(context);
                      context.go('/inbox');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerTile(
                    icon: Icons.open_in_new_rounded,
                    label: 'Open Campus++',
                    isActive: false, 
                    onTap: () async {
                      if (!widget.isDesktop) Navigator.pop(context);
                      final uri = Uri.parse('hhttps://hau.campus-erp.com/Student/Login.php');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Account & Settings',
                    isActive: widget.activeTab == 'account',
                    onTap: () {
                      if (!widget.isDesktop) Navigator.pop(context);
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
                  if (!widget.isDesktop) Navigator.pop(context);
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