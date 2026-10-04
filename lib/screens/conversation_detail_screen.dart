/// Conversation Thread Detail Screen (Canvas Parity)
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/safe_launch.dart';
import '../components/app_shell.dart';
import '../services/canvas_service.dart';
import '../services/error_text.dart';

class ConversationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> thread;
  const ConversationDetailScreen({super.key, required this.thread});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final CanvasService _canvasService = CanvasService();
  final TextEditingController _controller = TextEditingController();
  
  Map<String, dynamic>? _fullThread;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchThread();
  }

  Future<void> _fetchThread() async {
    try {
      final data = await _canvasService.fetchConversationDetail(widget.thread['id'].toString());
      if (mounted) {
        setState(() {
          _fullThread = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _canvasService.replyToConversation(widget.thread['id'].toString(), text);
      _controller.clear();
      await _fetchThread(); // Refresh thread to show new message
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e, 'Failed to send reply. Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleThreadAction(String action) async {
    try {
      if (action == 'archive') {
        await _canvasService.archiveConversation(widget.thread['id'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation archived')));
          context.pop(true);
        }
      } else if (action == 'delete') {
        await _canvasService.deleteConversation(widget.thread['id'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e, 'Something went wrong. Please try again.'))));
      }
    }
  }

  Future<void> _launchAttachment(String url) async {
    if (url.isEmpty) return;
    if (!await launchSafeUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open attachment.')));
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, yyyy · h:mm a').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = widget.thread['subject'] ?? 'Message Details';
    
    final List<dynamic> messages = _fullThread?['messages'] ?? widget.thread['messages'] ?? [];
    final List<dynamic> participants = _fullThread?['participants'] ?? widget.thread['participants'] ?? [];

    return AppShell(
      title: subject,
      activeTab: 'inbox',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => context.pop(true),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleThreadAction,
          color: theme.colorScheme.surface,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'archive',
              child: ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('Archive'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final authorId = msg['author_id'];
                    
                    // 1. Identify Sender
                    final authorData = participants.firstWhere(
                      (p) => p['id'] == authorId, 
                      orElse: () => {'name': 'Unknown Sender'}
                    );
                    final String authorName = authorData['name'] ?? 'Unknown Sender';

                    // 2. Identify Recipients (everyone in participants who is NOT the author)
                    final recipientsList = participants
                        .where((p) => p['id'] != authorId)
                        .map((p) => p['name'])
                        .toList();
                    final String toText = recipientsList.isNotEmpty ? recipientsList.join(', ') : 'Unknown';

                    // 3. Format Course and Subject Context
                    final String courseCode = widget.thread['context_name'] ?? widget.thread['courseCode'] ?? '';
                    final String subjectText = widget.thread['subject'] ?? 'No Subject';
                    final String contextLine = courseCode.isNotEmpty ? '$courseCode  ·  $subjectText' : subjectText;

                    // 4. Accurate Date Fallbacks
                    final String msgDate = msg['created_at'] ?? widget.thread['last_message_at'] ?? DateTime.now().toIso8601String();

                    final String body = msg['body'] ?? '';
                    final List<dynamic> attachments = msg['attachments'] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.scaffoldBackgroundColor,
                                  child: Icon(Icons.person, color: theme.colorScheme.secondary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Author & Timestamp Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              authorName,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(msgDate),
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // To: Line
                                      Text(
                                        'To: $toText',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Course & Subject Line
                                      Text(
                                        contextLine,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.secondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                          
                          // Rich HTML Message Body
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: HtmlWidget(
                              body,
                              onTapUrl: (url) async {
                                await _launchAttachment(url);
                                return true;
                              },
                              textStyle: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),

                          // Attachments Array
                          if (attachments.isNotEmpty) ...[
                            Container(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    final name = file['display_name'] ?? file['filename'] ?? 'Unknown File';
                                    final size = file['size'] ?? 0;
                                    final url = file['url'] ?? '';
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: InkWell(
                                        onTap: () => _launchAttachment(url),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: theme.scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.attach_file, size: 18, color: theme.colorScheme.primary),
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
                                                    Text(
                                                      _formatFileSize(size),
                                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(Icons.download_outlined, size: 18, color: theme.colorScheme.secondary),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
          ),
          
          // Reply Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Reply to conversation...',
                        hintStyle: TextStyle(color: theme.colorScheme.secondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _isSending ? theme.colorScheme.surface : theme.colorScheme.primary,
                    child: IconButton(
                      icon: _isSending 
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))
                          : Icon(Icons.send, color: theme.colorScheme.onPrimary, size: 18),
                      onPressed: _isSending ? null : _sendReply,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}