// Screen listing the user's active Canvas courses with the number of pending tasks in each.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../services/canvas_refresh.dart';
import '../services/canvas_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with CanvasRefreshMixin<CoursesScreen> {
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

  @override
  void onCanvasRefreshed() => _fetchData(silent: true);

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final courses = await _canvasService.fetchActiveCourses();

      Map<String, int> taskCounts = {};
      await Future.wait(courses.map((course) async {
        try {
          final tasks = await _canvasService.fetchRawAssignmentPayloads(course.id);
          int active = tasks.where((t) => !Task.submittedFromJson(t)).length;
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                  child: Text(
                    '${headerTerm.toUpperCase()} · ${_courses.length} COURSES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () {
                      CanvasService.requestFresh();
                      return _fetchData();
                    },
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      children: _courses.map((course) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildCourseCard(course, theme),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCourseCard(Course course, ThemeData theme) {
    final activeTasks = _activeTaskCounts[course.id] ?? 0;

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: () => context.push('/course', extra: course),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.courseCode,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${course.instructor} · ${course.term}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 14, color: theme.colorScheme.secondary),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            activeTasks > 0
                              ? '$activeTasks active task${activeTasks == 1 ? '' : 's'}'
                              : 'No active tasks',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
