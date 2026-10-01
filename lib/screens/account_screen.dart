// Account & Settings Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../components/app_shell.dart';
import '../state/app_state.dart';
import '../services/canvas_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final CanvasService _canvasService = CanvasService();
  
  Map<String, String> _userProfile = {
    'name': 'Loading...',
    'initials': '-',
    'program': 'Holy Angel University',
    'email': 'Loading...',
    'avatar_url': '',
    'bio': '',
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
    } catch (e) {}
  }

  void _openEditProfileSheet(ThemeData theme) {
    final bioController = TextEditingController(text: _userProfile['bio']);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                      Text('Edit Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Picture Upload
                  Center(
                    child: InkWell(
                      onTap: () async {
                        final result = await FilePicker.pickFiles(type: FileType.image);
                        if (result.isNotEmpty && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Avatar selected. (Canvas upload requires AWS S3 multipart integration)')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 32, color: theme.colorScheme.secondary),
                            const SizedBox(height: 8),
                            Text('Change Profile Picture', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Biography Edit
                  Text('Biography', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bioController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModalState(() => isSaving = true);
                        try {
                          await _canvasService.updateUserBio(bioController.text.trim());
                          await _fetchProfile(); // Refresh the local state
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            setModalState(() => isSaving = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary))
                          : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

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

  void _showCanvasAccountSheet(ThemeData theme) {
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
                  Text('Canvas Connection', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Account Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Email: ${_userProfile['email']}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Security Notice',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Velo authenticates using a secure Canvas API access token. Your university password is never requested, accessed, or stored on this device.',
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
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: _userProfile['avatar_url']!.isNotEmpty 
                    ? NetworkImage(_userProfile['avatar_url']!) 
                    : null,
                child: _userProfile['avatar_url']!.isEmpty
                    ? Text(
                        _userProfile['initials']!,
                        style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _userProfile['name']!.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _userProfile['program']!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Canvas Parity: Biography Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Biography', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () => _openEditProfileSheet(theme),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Profile'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: theme.scaffoldBackgroundColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userProfile['bio']!.isNotEmpty 
                          ? _userProfile['bio']! 
                          : 'No biography has been added',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _userProfile['bio']!.isNotEmpty ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
                        height: 1.5,
                        fontStyle: _userProfile['bio']!.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
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
                  label: 'Push notifications', sub: 'General Canvas updates',
                  value: appState.pushEnabled,
                  onToggle: appState.togglePushNotifications,
                ),
                _buildToggleRow(
                  theme: theme, icon: Icons.access_alarm_outlined,
                  label: 'Heads-up notifications', sub: 'Smart deadline alerts',
                  value: appState.headsUpEnabled,
                  onToggle: appState.toggleHeadsUpNotifications,
                  borderTop: true,
                ),
                
                // Expandable Settings Area
                if (appState.headsUpEnabled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.05))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Remind me before deadlines:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTimingChip(theme, appState, '1w', '1 Week'),
                            _buildTimingChip(theme, appState, '3d', '3 Days'),
                            _buildTimingChip(theme, appState, '1d', '1 Day'),
                            _buildTimingChip(theme, appState, '2h', '2 Hours'),
                          ],
                        ),
                      ],
                    ),
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
                  value: _userProfile['name'],
                  borderTop: true,
                  onTap: () => _showCanvasAccountSheet(theme),
                ),
              ],
            ),
          ),

          // Log Out
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('canvas_api_token');
                await prefs.remove('cache_user_profile');
                await prefs.remove('cache_active_courses');
                if (context.mounted) context.go('/');
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
              'Velo - Canvas Co-pilot · v1.0',
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

  Widget _buildTimingChip(ThemeData theme, AppState appState, String offset, String label) {
    final isSelected = appState.reminderOffsets.contains(offset);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      onSelected: (_) => appState.toggleReminderOffset(offset),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      checkmarkColor: theme.colorScheme.primary,
      backgroundColor: theme.scaffoldBackgroundColor,
      labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.1))
      ),
    );
  }
}