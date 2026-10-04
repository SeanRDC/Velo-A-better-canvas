// Inbox Screen
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../services/canvas_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final CanvasService _canvasService = CanvasService();
  
  static List<Map<String, dynamic>> _cachedThreads = [];
  List<Map<String, dynamic>> _threads = _cachedThreads;

  bool _isLoading = _cachedThreads.isEmpty;
  String? _errorMessage;
  String _activeFolder = 'inbox';

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  Future<void> _fetchInbox() async {
    final folder = _activeFolder;

    // Only block the screen with a spinner when there is nothing to show yet;
    // otherwise refresh in place so the list and scroll position are kept.
    setState(() {
      _isLoading = _threads.isEmpty;
      _errorMessage = null;
    });

    try {
      // 1. Fetch standard conversations (Direct Messages)
      final conversations = await _canvasService.fetchConversations(scope: folder);
      List<Map<String, dynamic>> combinedFeed = List.from(conversations);

      // 2. If viewing the Inbox, compile Announcements from all active courses
      if (folder == 'inbox') {
        final courses = await _canvasService.fetchActiveCourses();
        final announcementLists = await Future.wait(courses.map((course) async {
          try {
            final anns = await _canvasService.fetchAnnouncementsForCourse(course.id);
            return anns.map((a) {
              return {
                'id': 'ann_${a['id']}', 
                'kind': 'announcement',
                'workflow_state': a['read_state'] ?? 'read',
                'sender': a['user_name'] ?? 'Instructor',
                'context_name': course.courseCode,
                'subject': a['title'] ?? 'Announcement',
                'last_message': _stripHtml(a['message'] ?? ''),
                'full_html': a['message'] ?? '',
                'last_message_at': a['posted_at'] ?? a['created_at'],
              };
            }).toList();
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
        }));

        for (var list in announcementLists) {
          combinedFeed.addAll(list);
        }

        // Sort combined feed chronologically (newest first)
        combinedFeed.sort((a, b) {
          final dA = DateTime.parse(a['last_message_at'] ?? DateTime.now().toIso8601String());
          final dB = DateTime.parse(b['last_message_at'] ?? DateTime.now().toIso8601String());
          return dB.compareTo(dA);
        });
      }

      // Drop the result if the user switched folders while this was loading
      if (mounted && folder == _activeFolder) {
        if (folder == 'inbox') {
          final unread = combinedFeed.where((t) => t['workflow_state'] == 'unread' || t['unread'] == true).length;
          context.read<AppState>().updateUnreadInboxCount(unread);
          _cachedThreads = combinedFeed;
        }
        setState(() {
          _threads = combinedFeed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && folder == _activeFolder) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _markAsReadLocal(int index) {
    final t = _threads[index];
    if (t['workflow_state'] == 'unread' || t['unread'] == true) {
      setState(() {
        _threads[index]['workflow_state'] = 'read';
        _threads[index]['unread'] = false;
      });
      
      final unread = _threads.where((th) => th['workflow_state'] == 'unread' || th['unread'] == true).length;
      context.read<AppState>().updateUnreadInboxCount(unread);

      if (t['kind'] != 'announcement') {
        _canvasService.markConversationAsRead(t['id'].toString());
      }
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0 && date.day == now.day) {
        return DateFormat('h:mm a').format(date);
      } else if (diff.inDays == 1 || (diff.inDays == 0 && date.day != now.day)) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return DateFormat('E').format(date);
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _threads.where((t) => t['workflow_state'] == 'unread' || t['unread'] == true).length;

    return AppShell(
      title: 'Inbox',
      activeTab: 'inbox',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_square),
          onPressed: () async {
            final result = await context.push('/compose');
            if (result == true) _fetchInbox();
          },
          tooltip: 'Compose Message',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                if (!_isLoading && _errorMessage == null)
                  Text(
                    unreadCount > 0 ? '$unreadCount unread' : "You're all caught up",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFolderChip('Inbox', 'inbox', theme),
                const SizedBox(width: 8),
                _buildFolderChip('Sent', 'sent', theme),
                const SizedBox(width: 8),
                _buildFolderChip('Archived', 'archived', theme),
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
              Text('Failed to load inbox.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchInbox,
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

    if (_threads.isEmpty) {
      return Center(
        child: Text('No messages found.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.secondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInbox,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: _threads.length,
        itemBuilder: (context, index) {
          final t = _threads[index];
          final bool isUnread = t['workflow_state'] == 'unread' || t['unread'] == true;
          
          final List<dynamic> participants = t['participants'] ?? [];
          String senderName = t['sender'] ?? 'Unknown Sender';

          // Sent Folder: Show "To: Recipients". Inbox: Show Sender.
          if (_activeFolder == 'sent') {
            senderName = participants.isNotEmpty ? 'To: ${participants.map((p) => p['name']).join(', ')}' : 'To: Unknown';
          } else if (t['kind'] != 'announcement' && participants.isNotEmpty) {
            senderName = participants[0]['name'] ?? senderName;
          }

          final String courseCode = t['context_name'] ?? t['courseCode'] ?? '';
          final bool isAnnouncement = t['kind'] == 'announcement';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () async {
                  _markAsReadLocal(index);
                  
                  if (isAnnouncement) {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AppShell(
                        title: courseCode.isNotEmpty ? courseCode : 'Announcement',
                        activeTab: 'inbox',
                        leading: IconButton(
                          icon: const Icon(Icons.chevron_left, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                              t['subject'] ?? 'Announcement',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${t['sender']}  ·  ${_formatTime(t['last_message_at'] ?? t['time'])}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                            ),
                            const SizedBox(height: 24),
                            HtmlWidget(
                              t['full_html'] ?? t['last_message'] ?? '',
                              textStyle: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ));
                    _fetchInbox(); // Refresh when returning
                  } else {
                    final result = await context.push('/conversation', extra: t);
                    if (result == true) _fetchInbox();
                  }
                },
                borderRadius: BorderRadius.circular(12),

                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar & Unread Indicator (Megaphone for Announcements)
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Stack(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: isAnnouncement 
                                    ? theme.colorScheme.primary.withValues(alpha: 0.08) 
                                    : theme.scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAnnouncement ? Icons.campaign_outlined : Icons.person_outline, 
                                size: 18, 
                                color: isAnnouncement ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
                              ),
                            ),
                            if (isUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    senderName.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                      color: theme.colorScheme.secondary,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(t['last_message_at']),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            if (courseCode.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  courseCode,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],

                            Text(
                              t['subject'] ?? '(No Subject)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderChip(String label, String folder, ThemeData theme) {
    final isSelected = _activeFolder == folder;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _activeFolder = folder;
            _threads = [];
          });
          _fetchInbox();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}