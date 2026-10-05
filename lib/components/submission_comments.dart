// Comment thread on an assignment submission, with a field to post a new comment to Canvas.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/canvas_service.dart';

class SubmissionComments extends StatefulWidget {
  final List<dynamic> comments;
  final String? ownUserId;
  final Future<void> Function(String text) onSend;

  const SubmissionComments({
    super.key,
    required this.comments,
    required this.ownUserId,
    required this.onSend,
  });

  @override
  State<SubmissionComments> createState() => _SubmissionCommentsState();
}

class _SubmissionCommentsState extends State<SubmissionComments> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(dynamic createdAt) {
    final date = DateTime.tryParse(createdAt?.toString() ?? '');
    if (date == null) return '';
    return DateFormat('MMM d, h:mm a').format(date.toLocal());
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await widget.onSend(text);
      if (mounted) _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(readableError(e))));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMENTS',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),

        if (widget.comments.isEmpty)
          Text(
            'No comments yet.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          )
        else
          ...widget.comments.map((comment) => _buildComment(theme, comment)),

        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                enabled: !_isSending,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Add a comment...', filled: true, fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _controller.text.trim().isEmpty || _isSending ? null : _send,
              icon: _isSending
                  ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                  : const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComment(ThemeData theme, dynamic comment) {
    final bool isOwn = widget.ownUserId != null && comment['author_id']?.toString() == widget.ownUserId;
    final String author = isOwn ? 'You' : (comment['author_name'] ?? 'Unknown').toString();
    final String text = (comment['comment'] ?? '').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  author,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(comment['created_at']),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
