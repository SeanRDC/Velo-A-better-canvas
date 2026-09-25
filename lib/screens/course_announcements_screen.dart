// Course Announcements Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  
  // Controls the view state (null = list view, index = detail view)
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

  // Canvas returns raw HTML; this strips it for clean text rendering
  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Detail View Layout
    if (_selectedIndex != null) {
      final ann = _announcements[_selectedIndex!];
      final bodyText = _stripHtml(ann['message'] ?? 'No content provided.');

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
            const SizedBox(height: 20),
            Text(
              bodyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Material(
            color: theme.scaffoldBackgroundColor, // Flush with background
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
                          child: Text(
                            ann['title'] ?? 'Untitled',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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