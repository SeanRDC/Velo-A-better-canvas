// Main Application Layout Wrapper
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'bottom_nav.dart';
import 'side_drawer.dart';
import 'offline_banner.dart';

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
    final isOffline = context.watch<AppState>().isOffline;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(title),
            leading: isDesktop
                ? const SizedBox.shrink()
                : leading ?? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
            actions: actions,
          ),
          drawer: isDesktop ? null : SideDrawer(activeTab: activeTab, isDesktop: false),
          body: Row(
            children: [
              if (isDesktop)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
                  ),
                  child: SideDrawer(activeTab: activeTab, isDesktop: true),
                ),
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    if (isOffline) const OfflineBanner(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : BottomNav(activeTab: activeTab),
        );
      },
    );
  }
}