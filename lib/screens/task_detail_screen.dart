// Task detail screen showing an assignment's description and details, with a form to submit it
// and the comment thread on the submission.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../components/app_shell.dart';
import '../components/submission_comments.dart';
import '../components/submission_sheet.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../services/canvas_service.dart';
import '../services/safe_launch.dart';

class TaskDetailScreen extends StatefulWidget {
  final Course course;
  final Map<String, dynamic> assignment;

  const TaskDetailScreen({
    super.key,
    required this.course,
    required this.assignment,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final CanvasService _canvasService = CanvasService();

  late Map<String, dynamic> _assignment;
  Map<String, dynamic>? _submission;
  late bool _submitted;

  String? get _assignmentId => _assignment['id']?.toString();

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
    _submitted = Task.submittedFromJson(_assignment);
    _loadFromCanvas();
  }

  // The list screens pass in a cached copy, so the real submission state and the comment
  // thread are read from Canvas here.
  Future<void> _loadFromCanvas() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) return;

    try {
      final results = await Future.wait([
        _canvasService.fetchAssignment(widget.course.id, assignmentId),
        _canvasService.fetchMySubmission(widget.course.id, assignmentId),
      ]);
      if (!mounted) return;
      setState(() {
        _assignment = results[0];
        _submission = results[1];
        _submitted = Task.submittedFromJson({'submission': results[1]});
      });
    } catch (_) {}
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No due date';
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _submittedLabel() {
    final submittedAt = DateTime.tryParse(_submission?['submitted_at']?.toString() ?? '');
    if (submittedAt == null) return 'Submitted';
    return 'Submitted ${DateFormat('MMM d, h:mm a').format(submittedAt.toLocal())}';
  }

  Future<void> _launchExternalUrl(String url) async {
    if (url.isEmpty) return;
    final success = await launchSafeUrl(url);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  Future<void> _openSubmitSheet() async {
    final submitted = await showSubmissionSheet(
      context,
      courseId: widget.course.id,
      assignment: _assignment,
      resubmitting: _submitted,
    );
    if (!submitted || !mounted) return;

    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted to Canvas.')),
    );
    _loadFromCanvas();
  }

  Future<void> _sendComment(String text) async {
    await _canvasService.addSubmissionComment(widget.course.id, _assignmentId!, text);
    await _loadFromCanvas();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = _assignment;
    final submission = _submission;

    final bool isLocked = a['locked_for_user'] == true;
    final List<dynamic> types = a['submission_types'] ?? [];

    final bool isSubmittable = !isLocked && _assignmentId != null && (
      types.contains('online_upload') ||
      types.contains('online_text_entry') ||
      types.contains('online_url') ||
      types.contains('media_recording')
    );
    final String description = a['description'] ?? 'No instructions provided.';

    return AppShell(
      title: widget.course.courseCode,
      activeTab: 'courses',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => context.pop(),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                Text(
                  a['name'] ?? 'Untitled Task',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildMeta(theme, Icons.calendar_today, _formatDate(a['due_at']), 'Due Date'),
                    _buildMeta(theme, Icons.emoji_events_outlined, '${a['points_possible'] ?? 0} pts', 'Points Possible'),
                  ],
                ),

                if (_submitted) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(_submittedLabel(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],

                if (isLocked) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 32, color: theme.colorScheme.secondary),
                        const SizedBox(height: 12),
                        Text(
                          'Assignment Locked',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a['lock_explanation'] ?? 'This assignment is currently locked by the instructor.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Text(
                  'INSTRUCTIONS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),

                HtmlWidget(
                  description,
                  onTapUrl: (url) async {
                    await _launchExternalUrl(url);
                    return true;
                  },
                  textStyle: TextStyle(
                    fontSize: 16.0,
                    color: theme.colorScheme.onSurface,
                    height: 1.6,
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'a') {
                      return {'font-weight': '600', 'text-decoration': 'underline'};
                    }
                    return null;
                  },
                ),

                if (submission != null) ...[
                  const SizedBox(height: 32),
                  SubmissionComments(
                    comments: submission['submission_comments'] ?? [],
                    ownUserId: submission['user_id']?.toString(),
                    onSend: _sendComment,
                  ),
                ],
              ],
            ),
          ),

          if (isSubmittable)
            Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 16,
                bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 24,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openSubmitSheet,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _submitted ? 'Resubmit' : 'Submit Assignment',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeta(ThemeData theme, IconData icon, String label, String sub) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
          ],
        ),
      ],
    );
  }
}
