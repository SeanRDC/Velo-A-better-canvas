// Persistent Bottom Navigation Bar
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNav extends StatelessWidget {
  final String activeTab;

  const BottomNav({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            _buildTab(context, 'courses', 'Courses', Icons.menu_book_rounded, '/courses'),
            _buildTab(context, 'assistant', 'AI Assistant', Icons.smart_toy_outlined, '/assistant'),
            _buildTab(context, 'tasks', 'Dashboard', Icons.checklist_rtl, '/dashboard'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String key, String label, IconData icon, String path) {
    final theme = Theme.of(context);
    final isActive = activeTab == key;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) context.go(path);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: isActive 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}