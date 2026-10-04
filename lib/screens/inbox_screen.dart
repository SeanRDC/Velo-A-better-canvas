// Inbox screen listing Canvas conversations and course announcements by folder, with summary counts
// that double as filters, date grouping, and read tracking.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../services/canvas_refresh.dart';
import '../services/canvas_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with CanvasRefreshMixin<InboxScreen> {
  final CanvasService _canvasService = CanvasService();

  static List<Map<String, dynamic>> _cachedThreads = [];
  List<Map<String, dynamic>> _threads = _cachedThreads;
  static final Map<String, dynamic> _readLocally = {};

  bool _isLoading = _cachedThreads.isEmpty;
  String? _errorMessage;
  String _activeFolder = 'inbox';
  String _typeFilter = 'all';

  static const List<String> _groupOrder = ['Today', 'Yesterday', 'This week', 'Earlier'];

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  bool _isUnread(Map<String, dynamic> t) => t['workflow_state'] == 'unread' || t['unread'] == true;

  bool _isAnnouncement(Map<String, dynamic> t) => t['kind'] == 'announcement';

  @override
  void onCanvasRefreshed() => _fetchInbox();

  Future<void> _fetchInbox() async {
    if (!mounted) return;
    final folder = _activeFolder;

    setState(() {
      _isLoading = _threads.isEmpty;
      _errorMessage = null;
    });

    try {
      final conversations = await _canvasService.fetchConversations(scope: folder);
      List<Map<String, dynamic>> combinedFeed = List.from(conversations);

      if (folder == 'inbox') {
        final courses = await _canvasService.fetchActiveCourses();
        final announcementLists = await Future.wait(courses.map((course) async {
          try {
            final anns = await _canvasService.fetchAnnouncementsForCourse(course.id);
            return anns.map((a) {
              return {
                'id': 'ann_${a['id']}',
                'kind': 'announcement',
                'course_id': course.id,
                'topic_id': a['id'].toString(),
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

        combinedFeed.sort((a, b) {
          final dA = DateTime.parse(a['last_message_at'] ?? DateTime.now().toIso8601String());
          final dB = DateTime.parse(b['last_message_at'] ?? DateTime.now().toIso8601String());
          return dB.compareTo(dA);
        });
      }

      for (final t in combinedFeed) {
        final id = t['id'].toString();
        if (_readLocally.containsKey(id) && _readLocally[id] == t['last_message_at']) {
          t['workflow_state'] = 'read';
          t['unread'] = false;
        }
      }

      if (mounted && folder == _activeFolder) {
        if (folder == 'inbox') {
          final unread = combinedFeed.where(_isUnread).length;
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

  Future<void> _markAsRead(Map<String, dynamic> t) async {
    if (!_isUnread(t)) return;

    _readLocally[t['id'].toString()] = t['last_message_at'];
    setState(() {
      t['workflow_state'] = 'read';
      t['unread'] = false;
    });

    if (_activeFolder == 'inbox') {
      final unread = _threads.where(_isUnread).length;
      context.read<AppState>().updateUnreadInboxCount(unread);
    }

    try {
      if (_isAnnouncement(t)) {
        await _canvasService.markAnnouncementAsRead(t['course_id'].toString(), t['topic_id'].toString());
      } else {
        await _canvasService.markConversationAsRead(t['id'].toString());
      }
    } catch (_) {
    }
  }

  Future<void> _openThread(Map<String, dynamic> t) async {
    final theme = Theme.of(context);
    final String courseCode = t['context_name'] ?? t['courseCode'] ?? '';
    final marking = _markAsRead(t);

    if (_isAnnouncement(t)) {
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
      await marking;
      _fetchInbox();
    } else {
      final result = await context.push('/conversation', extra: t);
      await marking;
      if (result == true) _fetchInbox();
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

  String _groupOf(Map<String, dynamic> t) {
    final date = DateTime.tryParse(t['last_message_at']?.toString() ?? '')?.toLocal();
    if (date == null) return 'Earlier';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    if (!day.isBefore(today)) return 'Today';
    if (day == DateTime(now.year, now.month, now.day - 1)) return 'Yesterday';
    if (day.isAfter(DateTime(now.year, now.month, now.day - 7))) return 'This week';
    return 'Earlier';
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';

    String first(String word) => String.fromCharCode(word.runes.first).toUpperCase();
    return words.length == 1 ? first(words.first) : '${first(words.first)}${first(words.last)}';
  }

  void _setTypeFilter(String filter) {
    setState(() {
      _typeFilter = _typeFilter == filter ? 'all' : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final unreadCount = _threads.where(_isUnread).length;
    final announcementCount = _threads.where(_isAnnouncement).length;
    final messageCount = _threads.length - announcementCount;
    final hasData = !_isLoading && _errorMessage == null;

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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    theme,
                    value: hasData ? '$unreadCount' : '–',
                    label: 'Unread',
                    filter: 'unread',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    theme,
                    value: hasData ? '$messageCount' : '–',
                    label: 'Messages',
                    filter: 'messages',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    theme,
                    value: hasData ? '$announcementCount' : '–',
                    label: 'Announcements',
                    filter: 'announcements',
                  ),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
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

    final visible = _threads.where((t) {
      if (_typeFilter == 'unread') return _isUnread(t);
      if (_typeFilter == 'messages') return !_isAnnouncement(t);
      if (_typeFilter == 'announcements') return _isAnnouncement(t);
      return true;
    }).toList();

    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 64, width: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                child: Icon(Icons.inbox_outlined, size: 30, color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 16),
              Text('Nothing here', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _typeFilter == 'all' ? 'No messages in this folder.' : 'No messages match this filter.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<Widget>> groups = {};
    for (final t in visible) {
      groups.putIfAbsent(_groupOf(t), () => []).add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildThreadCard(t, theme),
      ));
    }

    final List<Widget> sections = [];
    for (final group in _groupOrder) {
      final cards = groups[group];
      if (cards == null) continue;
      sections.add(_buildDivider(group, cards.length, theme));
      sections.addAll(cards);
    }

    return RefreshIndicator(
      onRefresh: () {
        CanvasService.requestFresh();
        return _fetchInbox();
      },
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: sections,
      ),
    );
  }

  Widget _buildThreadCard(Map<String, dynamic> t, ThemeData theme) {
    final bool isUnread = _isUnread(t);
    final bool isAnnouncement = _isAnnouncement(t);

    final List<dynamic> participants = t['participants'] ?? [];
    String senderName = t['sender'] ?? 'Unknown Sender';
    String initialsSource = senderName;

    if (_activeFolder == 'sent') {
      senderName = participants.isNotEmpty ? 'To: ${participants.map((p) => p['name']).join(', ')}' : 'To: Unknown';
      initialsSource = participants.isNotEmpty ? (participants[0]['name'] ?? '').toString() : '';
    } else if (!isAnnouncement && participants.isNotEmpty) {
      senderName = participants[0]['name'] ?? senderName;
      initialsSource = senderName;
    }

    final String courseCode = t['context_name'] ?? t['courseCode'] ?? '';
    final String preview = (t['last_message'] ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    final String meta = [
      if (courseCode.isNotEmpty) courseCode,
      if (isAnnouncement) 'Announcement',
    ].join(' · ');

    final Color blockColor = isUnread ? theme.colorScheme.primary : theme.colorScheme.secondary.withValues(alpha: 0.12);
    final Color blockTextColor = isUnread ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: () => _openThread(t),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isAnnouncement
                    ? Icon(Icons.campaign_outlined, size: 24, color: blockTextColor)
                    : Text(
                        _initials(initialsSource),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: blockTextColor,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            senderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(t['last_message_at']),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                            color: isUnread ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t['subject'] ?? '(No Subject)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

  Widget _buildSummaryTile(
    ThemeData theme, {
    required String value,
    required String label,
    required String filter,
  }) {
    final isSelected = _typeFilter == filter;
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: isSelected ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: () => _setTypeFilter(filter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(String groupName, int count, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Text(
        '${groupName.toUpperCase()} · $count',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary,
          letterSpacing: 1.2,
        ),
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
            _typeFilter = 'all';
            _threads = [];
          });
          _fetchInbox();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
