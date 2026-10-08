// Strip shown above every screen in demo mode, telling the viewer the data is mock data.
import 'package:flutter/material.dart';
import '../services/demo_mode.dart';

class DemoBanner extends StatelessWidget {
  final Widget child;

  const DemoBanner({super.key, required this.child});

  static const Color _background = Color(0xFFFFD54F);
  static const Color _foreground = Color(0xFF1F1A00);

  @override
  Widget build(BuildContext context) {
    if (!DemoMode.enabled) return child;

    return Column(
      children: [
        Material(
          color: _background,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.science_outlined, size: 14, color: _foreground),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Demo mode: you are viewing Velo with mock data. Nothing here is real or sent to Canvas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _foreground,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The banner already sits below the status bar, so the screens must not leave room for it again.
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
        ),
      ],
    );
  }
}
