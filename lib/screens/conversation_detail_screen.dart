// Conversation Thread Detail Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/app_shell.dart';
import '../components/chat_bubble.dart';
import '../services/canvas_service.dart';

class ConversationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> thread;
  const ConversationDetailScreen({super.key, required this.thread});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final CanvasService _canvasService = CanvasService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
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
        _scrollToBottom();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reply: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Because ListView is reversed
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = widget.thread['subject'] ?? 'Message';
    
    // Canvas messages array is usually newest-first in the detail payload
    final List<dynamic> messages = _fullThread?['messages'] ?? widget.thread['messages'] ?? [];
    
    // Determine the ID of the person we are talking to, to align bubbles
    final participants = widget.thread['participants'] as List<dynamic>? ?? [];
    final primarySenderId = participants.isNotEmpty ? participants[0]['id'] : -1;

    return AppShell(
      title: subject,
      activeTab: 'inbox',
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 28),
        onPressed: () => context.pop(true), // Return true to signal a refresh
      ),
      child: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Start from bottom
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    // If author is the primary sender, it's incoming (left). Otherwise, it's the user (right).
                    final bool isUser = msg['author_id'] != primarySenderId;
                    
                    return ChatBubble(
                      text: msg['body'] ?? '',
                      isUser: isUser,
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
                        hintText: 'Type a reply...',
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