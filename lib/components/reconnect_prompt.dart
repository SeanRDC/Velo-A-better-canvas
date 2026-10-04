// Wraps the router and shows a dialog asking to leave offline mode once a connection is detected again.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ReconnectPrompt extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const ReconnectPrompt({super.key, required this.navigatorKey, required this.child});

  @override
  State<ReconnectPrompt> createState() => _ReconnectPromptState();
}

class _ReconnectPromptState extends State<ReconnectPrompt> {
  bool _isShowing = false;

  Future<void> _show() async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null || !mounted) {
      _isShowing = false;
      return;
    }

    final goOnline = await showDialog<bool>(
      context: navigatorContext,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          icon: Icon(Icons.wifi_outlined, color: theme.colorScheme.primary),
          title: const Text('Connection detected'),
          content: const Text(
            'You\'re in offline mode, but a connection is available again. Switch to online mode to sync the latest from Canvas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Stay offline'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Go online'),
            ),
          ],
        );
      },
    );

    _isShowing = false;
    if (!mounted) return;

    final appState = context.read<AppState>();
    if (goOnline == true) {
      appState.goOnline();
    } else {
      appState.dismissReconnectPrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldAsk = context.select<AppState, bool>((s) => s.reconnectAvailable);
    if (shouldAsk && !_isShowing) {
      _isShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
    return widget.child;
  }
}
