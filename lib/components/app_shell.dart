// Main Application Layout Wrapper
import 'package:flutter/material.dart';
import 'bottom_nav.dart';

class AppShell extends StatelessWidget {
  final String title;
  final String activeTab;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;

  const AppShell({
    super.key,
    required this.title,
    required this.activeTab,
    required this.child,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        leading: leading ?? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Open Side Drawer added in later update
          },
        ),
        actions: actions,
      ),
      body: child,
      bottomNavigationBar: BottomNav(activeTab: activeTab),
    );
  }
}