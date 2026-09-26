// Course Assignments Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../services/canvas_service.dart';

class CourseAssignmentsScreen extends StatefulWidget {
  final Course course;

  const CourseAssignmentsScreen({super.key, required this.course});

  @override
  State<CourseAssignmentsScreen> createState() => _CourseAssignmentsScreenState();
}

class _CourseAssignmentsScreenState extends State<CourseAssignmentsScreen> {
  final CanvasService _canvasService = CanvasService();
  
  List<Map<String, dynamic>> _originalAssignments = [];
  List<Map<String, dynamic>> _displayAssignments = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  bool _sortByDueSoon = false; // Tracks our toggle state

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
      final data = await _canvasService.fetchRawAssignmentPayloads(widget.course.id);
      setState(() {
        _originalAssignments = data;
        _applySort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySort() {
    if (!_sortByDueSoon) {
      _displayAssignments = List.from(_originalAssignments);
    } else {
      // Group by status
      final List<Map<String, dynamic>> pending = [];
      final List<Map<String, dynamic>> submitted = [];
      final List<Map<String, dynamic>> noDate = [];

      for (var a in _originalAssignments) {
        if (a['has_submitted_submissions'] == true) {
          submitted.add(a);
        } else if (a['due_at'] != null) {
          pending.add(a);
        } else {
          noDate.add(a);
        }
      }

      pending.sort((a, b) {
        final dA = DateTime.parse(a['due_at']);
        final dB = DateTime.parse(b['due_at']);
        return dA.compareTo(dB);
      });

      submitted.sort((a, b) {
        if (a['due_at'] == null) return 1;
        if (b['due_at'] == null) return -1;
        final dA = DateTime.parse(a['due_at']);
        final dB = DateTime.parse(b['due_at']);
        return dB.compareTo(dA); 
      });

      _displayAssignments = [...pending, ...noDate, ...submitted];
    }
  }

  String _formatDueDate(String? dateStr) {
    if (dateStr == null) return 'No due date';
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('E, MMM d').format(date);
  }

  Widget _buildStatusPill(ThemeData theme, Map<String, dynamic> assignment) {
    final bool hasSubmitted = assignment['has_submitted_submissions'] == true;
    final String? dueAt = assignment['due_at'];
    
    bool isOverdue = false;
    if (!hasSubmitted && dueAt != null) {
      final dueDate = DateTime.parse(dueAt).toLocal();
      if (dueDate.isBefore(DateTime.now())) {
        isOverdue = true;
      }
    }

    String label = 'Upcoming';
    Color bgColor = theme.colorScheme.secondary.withValues(alpha: 0.1);
    Color textColor = theme.colorScheme.secondary;

    if (hasSubmitted) {
      label = 'Submitted';
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.primary;
    } else if (isOverdue) {
      label = 'Overdue';
      bgColor = theme.colorScheme.error;
      textColor = theme.colorScheme.onError;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
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
                        '${_displayAssignments.length} assignments',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
                
                // Sort Toggle Button
                if (!_isLoading && _errorMessage == null && _displayAssignments.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _sortByDueSoon = !_sortByDueSoon;
                        _applySort();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _sortByDueSoon 
                            ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                            : theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort, 
                            size: 16, 
                            color: _sortByDueSoon ? theme.colorScheme.primary : theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _sortByDueSoon ? 'Due Soon' : 'Default',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _sortByDueSoon ? theme.colorScheme.primary : theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
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
              Text('Failed to load assignments.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchAssignments,
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, elevation: 0),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_displayAssignments.isEmpty) {
      return Center(
        child: Text('No assignments found.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      itemCount: _displayAssignments.length,
      itemBuilder: (context, index) {
        final a = _displayAssignments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              context.push('/task', extra: {
                'course': widget.course,
                'assignment': a,
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['name'] ?? 'Untitled Assignment',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Due ${_formatDueDate(a['due_at'])} · ${a['points_possible'] ?? 0} pts',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusPill(theme, a),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}