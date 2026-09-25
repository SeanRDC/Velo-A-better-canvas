// Course Detail Hub Screen
import 'package:flutter/material.dart';
import '../components/app_shell.dart';
import '../models/course.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Navigation Tiles Configuration
    final List<Map<String, dynamic>> sections = [
      {'icon': Icons.campaign_outlined, 'title': 'Announcements', 'sub': 'View posts', 'path': '/course-announcements'},
      {'icon': Icons.grid_view_rounded, 'title': 'Modules', 'sub': 'Course materials', 'path': '/course-modules'},
      {'icon': Icons.school_outlined, 'title': 'Grades', 'sub': 'Current grade', 'path': '/course-grades'},
      {'icon': Icons.assignment_outlined, 'title': 'Assignments', 'sub': 'View tasks', 'path': '/course-assignments'},
    ];

    return AppShell(
      title: course.courseCode,
      activeTab: 'courses',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Course Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMetaRow(Icons.menu_book, 'Instructor Name', theme),
                const SizedBox(height: 6),
                _buildMetaRow(Icons.calendar_today, 'Spring 2026', theme),
                const SizedBox(height: 6),
                _buildMetaRow(Icons.location_on_outlined, 'Online', theme),
              ],
            ),
          ),

          // Navigable Tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: sections.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // TODO: Implement sub-screen routing
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Row(
                          children: [
                            // Icon Circle
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                s['icon'],
                                size: 20,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Title & Sub
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['title'],
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s['sub'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}