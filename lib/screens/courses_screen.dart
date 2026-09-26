// Courses Master Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../services/canvas_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final CanvasService _canvasService = CanvasService();
  
  List<Course> _courses = [];
  Map<String, int> _activeTaskCounts = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await _canvasService.fetchActiveCourses();
      
      // Concurrently fetch active task counts per course without blocking the UI rendering
      Map<String, int> taskCounts = {};
      await Future.wait(courses.map((course) async {
        try {
          final tasks = await _canvasService.fetchRawAssignmentPayloads(course.id);
          int active = tasks.where((t) => t['has_submitted_submissions'] != true).length;
          taskCounts[course.id] = active;
        } catch (_) {
          taskCounts[course.id] = 0;
        }
      }));

      if (mounted) {
        setState(() {
          _courses = courses;
          _activeTaskCounts = taskCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  
    final String headerTerm = _courses.isNotEmpty ? _courses.first.term : 'Current Term';

    return AppShell(
      title: 'My Courses',
      activeTab: 'courses',
      child: _isLoading 
        ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
        : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                  child: Text(
                    '$headerTerm · ${_courses.length} courses',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                
                // Course list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      final activeTasks = _activeTaskCounts[course.id] ?? 0;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => context.push('/course', extra: course),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              course.courseCode,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            course.name,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurface,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${course.instructor} · ${course.term}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, size: 24, color: theme.colorScheme.secondary),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.menu_book, size: 14, color: theme.colorScheme.secondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      activeTasks > 0 
                                        ? '$activeTasks active task${activeTasks == 1 ? '' : 's'}' 
                                        : 'No active tasks',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}