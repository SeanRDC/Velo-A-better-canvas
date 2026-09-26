// Account & Settings Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../components/app_shell.dart';
import '../state/app_state.dart';

const _currentUser = {
  'name': 'Sean Rhani Jarin Dela Cruz',
  'initials': 'SD',
  'program': 'Holy Angel University',
  'email': 'sean.delacruz@student.hau.edu.ph',
};

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Local state for the push notification toggle since it doesn't need global persistence yet
  bool _pushEnabled = true;

  void _showPrivacySheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 24,
            left: 24, right: 24, top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4, width: 40,
                  decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Privacy & Data', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Local-First Architecture',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Velo is a strictly local-first application. User profiles, Canvas tokens, and cached course tasks are stored entirely on this device using encrypted local storage. No personal data is ever sent to a third-party Velo database.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Official Infrastructure',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'The application relies exclusively on the Canvas LMS as the definitive backend. All data security, transit encryption, and authentication are handled entirely by the official university LMS infrastructure.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final isDark = appState.themeMode == ThemeMode.dark;

    return AppShell(
      title: 'Account',
      activeTab: 'account',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          // Profile Section
          Column(
            children: [
              Container(
                height: 80, width: 80,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  _currentUser['initials']!,
                  style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _currentUser['name']!,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                _currentUser['program']!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                _currentUser['email']!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          // Appearance
          const SizedBox(height: 32),
          Text(
            'APPEARANCE',
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => appState.setTheme(ThemeMode.light),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isDark ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.light_mode_outlined, size: 16, color: !isDark ? theme.colorScheme.onPrimary : theme.colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text('Light', style: TextStyle(fontWeight: FontWeight.w600, color: !isDark ? theme.colorScheme.onPrimary : theme.colorScheme.secondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => appState.setTheme(ThemeMode.dark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dark_mode_outlined, size: 16, color: isDark ? theme.colorScheme.onPrimary : theme.colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text('Dark', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? theme.colorScheme.onPrimary : theme.colorScheme.secondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Preferences
          const SizedBox(height: 24),
          Text(
            'PREFERENCES',
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _buildToggleRow(
                  theme: theme, icon: Icons.notifications_none_outlined,
                  label: 'Push notifications', sub: 'Deadlines and announcements',
                  value: _pushEnabled,
                  onToggle: () => setState(() => _pushEnabled = !_pushEnabled),
                ),
                _buildToggleRow(
                  theme: theme, icon: Icons.wifi_off_outlined,
                  label: 'Offline mode', sub: 'Read from local cache',
                  value: appState.isOffline,
                  onToggle: appState.toggleOffline,
                  borderTop: true,
                ),
              ],
            ),
          ),

          // Account
          const SizedBox(height: 24),
          Text(
            'ACCOUNT',
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _buildLinkRow(
                  theme: theme, icon: Icons.shield_outlined,
                  label: 'Privacy & data',
                  onTap: () => _showPrivacySheet(theme),
                ),
                _buildLinkRow(
                  theme: theme, icon: Icons.link_outlined,
                  label: 'Connected Canvas account',
                  value: _currentUser['name'],
                  borderTop: true,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Log Out
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // In a production app, you would clear shared_preferences here
                context.go('/');
              },
              icon: Icon(Icons.logout, size: 18, color: theme.colorScheme.onSurface),
              label: Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'A Better Canvas · v1.0',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required ThemeData theme, required IconData icon,
    required String label, required String sub,
    required bool value, required VoidCallback onToggle,
    bool borderTop = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: borderTop ? Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))) : null,
      ),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 36, width: 36,
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                  ],
                ),
              ),
              // Custom animated pill switch
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 24,
                decoration: BoxDecoration(
                  color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      left: value ? 22.0 : 2.0,
                      right: value ? 2.0 : 22.0,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkRow({
    required ThemeData theme, required IconData icon,
    required String label, String? value,
    required VoidCallback onTap, bool borderTop = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: borderTop ? Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))) : null,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 36, width: 36,
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (value != null)
                Text(value, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}