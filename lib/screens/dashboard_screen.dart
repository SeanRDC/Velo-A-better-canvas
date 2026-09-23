// Master Dashboard Screen
import 'package:flutter/material.dart';
import '../components/app_shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'My Tasks',
      activeTab: 'tasks',
      child: const Center(
        child: Text('Dashboard Feed Coming Soon'),
      ),
    );
  }
}