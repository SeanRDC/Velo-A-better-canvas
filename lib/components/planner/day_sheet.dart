// Bottom sheet listing everything due or scheduled on one calendar day.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import 'todays_focus_card.dart';

Future<void> showDaySheet(
  BuildContext context, {
  required DateTime date,
  required List<Task> tasks,
  required List<FocusStep> steps,
  required void Function(Task task) onTaskTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final points = tasks.fold<int>(0, (sum, t) => sum + t.points);

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(DateFormat('EEEE, MMM d').format(date), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                tasks.isEmpty ? 'Nothing due' : '${tasks.length} due • $points pts',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 16),
              ...tasks.map((t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.assignment_outlined, color: theme.colorScheme.primary),
                    title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${t.courseCode} • ${DateFormat('h:mm a').format(t.dueDate)} • ${t.points} pts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onTaskTap(t);
                    },
                  )),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'PLANNED STEPS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.0,
                  ),
                ),
                ...steps.map((s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        s.milestone.isDone ? Icons.check_circle : Icons.circle_outlined,
                        color: s.milestone.isDone ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      title: Text(s.milestone.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(s.plan.taskTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
              ],
            ],
          ),
        ),
      );
    },
  );
}
