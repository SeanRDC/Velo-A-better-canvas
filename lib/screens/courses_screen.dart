// Enrolled Courses Screen Placeholder
import 'package:flutter/material.dart';
import '../components/app_shell.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'My Courses',
      activeTab: 'courses',
      child: Center(
        child: Text('Course Feed Coming Soon'),
      ),
    );
  }
}