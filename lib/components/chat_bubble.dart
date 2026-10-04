// Chat bubble component for the AI Assistant interface
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Keeps lines readable on tablets and desktop instead of spanning the window
  static const double _maxBubbleWidth = 720;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _copied = false;

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

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);

    // Flip the icon back after a moment
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final lineColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.4, fontSize: 14);

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
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 16,
                    left: widget.isUser ? 48 : 0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxBubbleWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: widget.isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(widget.isUser ? 20 : 4),
                              topRight: Radius.circular(widget.isUser ? 4 : 20),
                              bottomLeft: const Radius.circular(20),
                              bottomRight: const Radius.circular(20),
                            ),
                            border: widget.isUser ? null : Border.all(color: lineColor),
                          ),
                          // SelectionArea (long-press to select) rather than selectable
                          // text, which would swallow the sideways drag that scrolls tables
                          child: SelectionArea(
                           child: MarkdownBody(
                            onTapLink: (text, href, title) {
                              if (href != null && widget.onLinkTap != null) {
                                widget.onLinkTap!(href);
                              }
                            },
                            data: widget.text,
                            styleSheet: MarkdownStyleSheet(
                              p: bodyStyle,
                              strong: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              em: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontStyle: FontStyle.italic, fontSize: 14),
                              listBullet: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontSize: 14),
                              listIndent: 20,
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
                              blockquoteDecoration: BoxDecoration(
                                border: Border(left: BorderSide(color: lineColor, width: 3)),
                              ),
                              blockquotePadding: const EdgeInsets.only(left: 12),
                              horizontalRuleDecoration: BoxDecoration(
                                border: Border(top: BorderSide(color: lineColor)),
                              ),

                              // Tables keep their natural column widths and scroll
                              // sideways, instead of being squeezed to fit a phone
                              tableColumnWidth: const IntrinsicColumnWidth(),
                              tableScrollbarThumbVisibility: true,
                              tablePadding: const EdgeInsets.only(bottom: 10),
                              tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              tableBorder: TableBorder.all(color: lineColor),
                              tableHead: bodyStyle?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                              tableBody: bodyStyle?.copyWith(fontSize: 13),
                              tableHeadAlign: TextAlign.left,
                              tableCellsDecoration: const BoxDecoration(),
                            ),
                           ),
                          ),
                        ),

                        // Copy the reply as text
                        if (!widget.isUser)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 4),
                            child: InkWell(
                              onTap: _copyText,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _copied ? Icons.check : Icons.copy_outlined,
                                      size: 13,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _copied ? 'Copied' : 'Copy',
                                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
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
