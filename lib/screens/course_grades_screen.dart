// Course Grades Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../models/course.dart';

// Temporary model until we wire up the Canvas enrollments/grades endpoint
class GradeItem {
  final String label;
  final num score;
  final num total;
  GradeItem(this.label, this.score, this.total);
}

class CourseGradesScreen extends StatefulWidget {
  final Course course;

  const CourseGradesScreen({super.key, required this.course});

  @override
  State<CourseGradesScreen> createState() => _CourseGradesScreenState();
}

class _CourseGradesScreenState extends State<CourseGradesScreen> {
  // Hardcoded for UI layout testing; replacing with live Canvas data next
  final List<GradeItem> _items = [
    GradeItem('Quiz 3 Link-State Routing', 88, 100),
    GradeItem('Switching Fundamentals Lab', 54, 60),
    GradeItem('Midterm Exam', 141, 160),
  ];
  
  final num _pct = 88;
  final String _letter = 'B+';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Grades',
      activeTab: 'courses',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => context.pop(),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.courseCode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_items.length} graded items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Summary Block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current grade',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_pct%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _letter,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grades List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isFirst = index == 0;
                  
                  return Container(
                    decoration: BoxDecoration(
                      border: isFirst 
                          ? null 
                          : Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${item.score}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '/${item.total}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}