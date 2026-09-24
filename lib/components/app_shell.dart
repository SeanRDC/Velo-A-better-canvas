// Main Application Layout Wrapper
import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import 'side_drawer.dart';

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
        leading: leading ?? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: actions,
      ),
      drawer: const SideDrawer(),
      body: child,
      bottomNavigationBar: BottomNav(activeTab: activeTab),
    );
  }
}