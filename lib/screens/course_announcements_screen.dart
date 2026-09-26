// Course Announcements Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import '../components/app_shell.dart';
import '../models/course.dart';
import '../services/canvas_service.dart';

class CourseAnnouncementsScreen extends StatefulWidget {
  final Course course;

  const CourseAnnouncementsScreen({super.key, required this.course});

  @override
  State<CourseAnnouncementsScreen> createState() => _CourseAnnouncementsScreenState();
}

class _CourseAnnouncementsScreenState extends State<CourseAnnouncementsScreen> {
  final CanvasService _canvasService = CanvasService();
  
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _canvasService.fetchAnnouncementsForCourse(widget.course.id);
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Used only for the list view preview snippets
  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _launchLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Detail View Layout (Rich HTML)
    if (_selectedIndex != null) {
      final ann = _announcements[_selectedIndex!];
      final List<dynamic> attachments = ann['attachments'] ?? [];

      return AppShell(
        title: widget.course.courseCode,
        activeTab: 'courses',
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => setState(() => _selectedIndex = null),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.campaign_outlined, size: 20, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Text(
              ann['title'] ?? 'Untitled Announcement',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ann['user_name'] ?? 'Instructor'} · ${_formatDate(ann['posted_at'])}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            
            // Rich HTML Rendering
            Html(
              data: ann['message'] ?? 'No content provided.',
              onLinkTap: (url, attributes, element) {
                if (url != null) _launchLink(url);
              },
              style: {
                "body": Style(
                  fontSize: FontSize(16.0),
                  color: theme.colorScheme.onSurface,
                  lineHeight: LineHeight(1.6),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "a": Style(
                  color: theme.colorScheme.primary,
                  textDecoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 12.0),
                ),
              },
            ),
            
            // Render Attachments Block
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'ATTACHMENTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: theme.colorScheme.secondary, 
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              ...attachments.map((file) {
                final name = file['display_name'] ?? 'Unknown File';
                final size = file['size'] ?? 0;
                final url = file['url'] ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => _launchLink(url),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatFileSize(size),
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.download_outlined, size: 20, color: theme.colorScheme.secondary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }

    // List View Layout
    return AppShell(
      title: 'Announcements',
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
                    '${_announcements.length} announcements',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildListContent(theme)),
        ],
      ),
    );
  }

  Widget _buildListContent(ThemeData theme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load announcements.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchAnnouncements,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Text(
          'No announcements found.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        final cleanBody = _stripHtml(ann['message'] ?? '');
        final hasAttachments = (ann['attachments'] as List<dynamic>? ?? []).isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: InkWell(
              onTap: () => setState(() => _selectedIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ann['title'] ?? 'Untitled',
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasAttachments) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.attach_file, size: 14, color: theme.colorScheme.secondary),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(ann['posted_at']),
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ann['user_name'] ?? 'Instructor',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cleanBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}