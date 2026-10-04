// Banner shown while offline mode is on, telling the user when the saved data was last synced.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    
    String syncText = 'Never synced';
    
    if (appState.lastSyncTime != null) {
      try {
        final date = DateTime.parse(appState.lastSyncTime!).toLocal();
        syncText = 'Last synced ${DateFormat('MMM d, h:mm a').format(date)}';
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off_outlined, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Offline   showing saved tasks',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            syncText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}