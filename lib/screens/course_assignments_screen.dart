// Course Assignments Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../services/canvas_service.dart';

class CourseAssignmentsScreen extends StatefulWidget {
  final Course course;

  const CourseAssignmentsScreen({super.key, required this.course});

  @override
  State<CourseAssignmentsScreen> createState() => _CourseAssignmentsScreenState();
}

class _CourseAssignmentsScreenState extends State<CourseAssignmentsScreen> {
  final CanvasService _canvasService = CanvasService();
  
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _canvasService.fetchAssignmentsForCourse(widget.course);
      // Sort tasks chronologically by due date
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDueDate(DateTime date) {
    return DateFormat('E, MMM d').format(date);
  }

  String _getRelativeLabel(DateTime date, bool isSubmitted) {
    if (isSubmitted) return 'Submitted';
    final diff = date.difference(DateTime.now()).inDays;
    if (diff < 0) return '${diff.abs()}d overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return '${diff}d left';
  }

  Widget _buildStatusPill(Task task, ThemeData theme) {
    final diff = task.dueDate.difference(DateTime.now()).inDays;
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (task.isSubmitted) {
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.15);
      textColor = theme.colorScheme.secondary;
      icon = Icons.check_circle_outline;
      label = 'Submitted';
    } else if (diff < 0) {
      bgColor = theme.colorScheme.error;
      textColor = theme.colorScheme.onError;
      icon = Icons.error_outline;
      label = 'Overdue';
    } else if (diff <= 3) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.primary;
      icon = Icons.schedule;
      label = 'Due soon';
    } else {
      bgColor = theme.colorScheme.secondary.withValues(alpha: 0.15);
      textColor = theme.colorScheme.onSurface;
      icon = Icons.calendar_today;
      label = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Assignments',
      activeTab: 'courses',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => context.pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                if (!_isLoading && _errorMessage == null)
                  Text(
                    '${_tasks.length} assignments',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _buildContent(theme),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load assignments.',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchAssignments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Text(
          'No assignments found.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            final isFirst = index == 0;

            return InkWell(
              onTap: () {
                context.push('/task', extra: {'course': widget.course, 'task': task});
              },
              borderRadius: isFirst 
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : (index == _tasks.length - 1 
                      ? const BorderRadius.vertical(bottom: Radius.circular(16)) 
                      : BorderRadius.zero),
              child: Container(
                decoration: BoxDecoration(
                  border: isFirst 
                      ? null 
                      : Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDueDate(task.dueDate)} · ${_getRelativeLabel(task.dueDate, task.isSubmitted)} · ${task.points} pts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusPill(task, theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}