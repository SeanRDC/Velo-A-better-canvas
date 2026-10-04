// Chat bubble component for the AI Assistant interface
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ChatBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final void Function(String)? onLinkTap;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.onLinkTap,
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isUser) ...[
                const SizedBox(width: 16),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.smart_toy_outlined, size: 16, color: theme.colorScheme.onPrimary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  margin: EdgeInsets.only(
                    right: 16,
                    left: widget.isUser ? 48 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: widget.isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(widget.isUser ? 20 : 4),
                      topRight: Radius.circular(widget.isUser ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    border: widget.isUser
                        ? null
                        : Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                  ),
                  child: MarkdownBody(
                    onTapLink: (text, href, title) {
                      if (href != null && widget.onLinkTap != null) {
                        widget.onLinkTap!(href);
                      }
                    },
                    data: widget.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.4, fontSize: 14),
                      strong: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      em: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontStyle: FontStyle.italic, fontSize: 14),
                      listBullet: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontSize: 14),
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
            ],
          ),
        ),
      ),
    );
  }
}