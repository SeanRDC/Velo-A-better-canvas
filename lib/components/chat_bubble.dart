// Chat bubble component for the AI Assistant interface
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatefulWidget {
  final String text;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // Configure the sleek entrance animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    // User bubbles slide in from the right, AI bubbles from the left
    _slide = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.1 : -0.1, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Align(
          alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(widget.isUser ? 16 : 4),
                bottomRight: Radius.circular(widget.isUser ? 4 : 16),
              ),
              border: widget.isUser
                  ? null
                  : Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
            ),
            child: MarkdownBody(
              data: widget.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.4),
                strong: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                em: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontStyle: FontStyle.italic),
                listBullet: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                h1: theme.textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                h2: theme.textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                h3: theme.textTheme.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                code: theme.textTheme.bodySmall?.copyWith(
                  backgroundColor: Colors.transparent,
                  color: widget.isUser ? theme.colorScheme.surface : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                codeblockDecoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}