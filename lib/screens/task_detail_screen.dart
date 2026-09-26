// Task Detail Screen (Assignment Parity)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/app_shell.dart';
import '../models/course.dart';

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
  String _selectedTab = 'file';
  String? _fileName;
  final TextEditingController _textController = TextEditingController();
  
  late bool _submitted;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _submitted = widget.assignment['has_submitted_submissions'] == true;
    
    // Auto-select the first available submission type tab
    final List<dynamic> types = widget.assignment['submission_types'] ?? [];
    if (types.contains('online_upload')) {
      _selectedTab = 'file';
    } else if (types.contains('online_text_entry')) {
      _selectedTab = 'text';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No due date';
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _launchExternalUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  void _doSubmit() async {
    setState(() => _isUploading = true);
    // Real API submission call would go here
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _isUploading = false;
      _submitted = true;
    });
  }

  void _openSubmitSheet(ThemeData theme) {
    final List<dynamic> types = widget.assignment['submission_types'] ?? [];
    final bool allowsFile = types.contains('online_upload');
    final bool allowsText = types.contains('online_text_entry');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final canSubmit = (_selectedTab == 'file' && _fileName != null) || 
                              (_selectedTab == 'text' && _textController.text.trim().isNotEmpty);
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24, top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4, width: 40,
                      decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Submit work', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Conditional Tabs based on Canvas payload
                  if (allowsFile && allowsText)
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => _selectedTab = 'file'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 'file' ? theme.colorScheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text('File upload', style: TextStyle(fontWeight: FontWeight.w600, color: _selectedTab == 'file' ? theme.colorScheme.onPrimary : theme.colorScheme.secondary)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => _selectedTab = 'text'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 'text' ? theme.colorScheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text('Text entry', style: TextStyle(fontWeight: FontWeight.w600, color: _selectedTab == 'text' ? theme.colorScheme.onPrimary : theme.colorScheme.secondary)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // File Input
                  if (_selectedTab == 'file' && allowsFile)
                    _fileName != null 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_fileName!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
                              InkWell(
                                onTap: () => setModalState(() => _fileName = null),
                                child: Text('Remove', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                              )
                            ],
                          ),
                        )
                      : InkWell(
                          onTap: () => setModalState(() => _fileName = 'selected_assignment_file.pdf'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 32, color: theme.colorScheme.secondary),
                                const SizedBox(height: 8),
                                Text('Choose a file', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        
                  // Text Input
                  if (_selectedTab == 'text' && allowsText)
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      onChanged: (val) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Type your submission here...', filled: true, fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSubmit && !_isUploading ? _doSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isUploading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                          : Text(_submitted ? 'Resubmit' : 'Submit to Canvas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.assignment;
    
    final bool isLocked = a['locked_for_user'] == true;
    final List<dynamic> types = a['submission_types'] ?? [];
    
    // Determine if this assignment can be submitted through the app
    final bool isSubmittable = !isLocked && (types.contains('online_upload') || types.contains('online_text_entry'));
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
                
                // Meta Tags
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
                        Text('Submitted', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                
                // Rich HTML Rendering
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
              ],
            ),
          ),
          
          // Persistent Submission Bar
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
                  onPressed: () => _openSubmitSheet(theme),
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