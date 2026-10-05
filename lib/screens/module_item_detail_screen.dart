// Screen showing a single module item's content with previous/next navigation and assignment submission.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/safe_launch.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../components/app_shell.dart';
import '../components/submission_comments.dart';
import '../components/submission_sheet.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../services/canvas_service.dart';
import 'course_modules_screen.dart';

class ModuleItemDetailScreen extends StatefulWidget {
  final Course course;
  final List<ModuleItem> items;
  final int initialIndex;

  const ModuleItemDetailScreen({
    super.key,
    required this.course,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<ModuleItemDetailScreen> createState() => _ModuleItemDetailScreenState();
}

class _ModuleItemDetailScreenState extends State<ModuleItemDetailScreen> {
  final CanvasService _canvasService = CanvasService();
  
  late int _currentIndex;
  String _htmlContent = '';
  bool _isLoading = true;
  
  Map<String, dynamic>? _assignment;
  Map<String, dynamic>? _submission;

  bool get _submitted => _submission != null && Task.submittedFromJson({'submission': _submission});

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadCurrentItem();
  }

  String? _assignmentIdOf(ModuleItem item) {
    if (item.kind.toLowerCase() != 'assignment' || item.apiUrl == null) return null;
    return RegExp(r'/assignments/(\d+)').firstMatch(item.apiUrl!)?.group(1);
  }

  Future<void> _loadCurrentItem() async {
    final index = _currentIndex;
    setState(() {
      _isLoading = true;
      _assignment = null;
      _submission = null;
    });
    final item = widget.items[index];

    final html = await _canvasService.fetchModuleItemHtml(
      widget.course.id,
      item.kind,
      item.pageUrl,
      item.apiUrl,
    );

    if (!mounted || index != _currentIndex) return;
    setState(() {
      _htmlContent = html;
      _isLoading = false;
    });

    final assignmentId = _assignmentIdOf(item);
    if (assignmentId != null) _loadSubmission(index, assignmentId);
  }

  // Reads the assignment's rules and the student's real submission from Canvas, so the submit
  // button and the comment thread reflect what Canvas has.
  Future<void> _loadSubmission(int index, String assignmentId) async {
    try {
      final results = await Future.wait([
        _canvasService.fetchAssignment(widget.course.id, assignmentId),
        _canvasService.fetchMySubmission(widget.course.id, assignmentId),
      ]);
      if (!mounted || index != _currentIndex) return;
      setState(() {
        _assignment = results[0];
        _submission = results[1];
      });
    } catch (_) {}
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadCurrentItem();
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() => _currentIndex++);
      _loadCurrentItem();
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    if (url.isEmpty) return;
    await launchSafeUrl(url);
  }

  Future<void> _openSubmitSheet() async {
    final assignment = _assignment;
    if (assignment == null) return;

    final submitted = await showSubmissionSheet(
      context,
      courseId: widget.course.id,
      assignment: assignment,
      resubmitting: _submitted,
    );
    if (!submitted || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted to Canvas.')),
    );
    await _loadSubmission(_currentIndex, assignment['id'].toString());
  }

  Future<void> _sendComment(String text) async {
    final assignmentId = _assignment!['id'].toString();
    await _canvasService.addSubmissionComment(widget.course.id, assignmentId, text);
    await _loadSubmission(_currentIndex, assignmentId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentItem = widget.items[_currentIndex];
    
    final canGoBack = _currentIndex > 0;
    final canGoForward = _currentIndex < widget.items.length - 1;

    final assignment = _assignment;
    final submission = _submission;
    final List<dynamic> types = assignment?['submission_types'] ?? [];
    final bool isSubmittable = assignment != null &&
        assignment['locked_for_user'] != true &&
        (types.any(inAppSubmissionTypes.contains) || types.contains('media_recording'));

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
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentItem.kind.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentItem.label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_htmlContent.isNotEmpty)
                      HtmlWidget(
                        _htmlContent,
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
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.launch, size: 48, color: theme.colorScheme.secondary),
                            const SizedBox(height: 16),
                            Text(
                              'This item requires Canvas',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap below to open this ${currentItem.kind} securely in your browser.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _launchExternalUrl(currentItem.htmlUrl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                elevation: 0,
                              ),
                              child: const Text('Open in Canvas'),
                            ),
                          ],
                        ),
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
          
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12, 
              bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSubmittable) ...[
                  SizedBox(
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: canGoBack ? _goToPrevious : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        disabledForegroundColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    TextButton(
                      onPressed: canGoForward ? _goToNext : null,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        disabledForegroundColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Next'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}