// Card summarising the milestones to work on today across every saved study plan.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/milestone.dart';
import '../../models/task.dart';

class FocusStep {
  final StudyPlan plan;
  final Milestone milestone;

  const FocusStep(this.plan, this.milestone);
}

class TodaysFocusCard extends StatelessWidget {
  final List<FocusStep> steps;
  final List<Task> dueSoon;
  final void Function(FocusStep step) onToggle;
  final void Function(String taskId) onOpenPlan;

  const TodaysFocusCard({
    super.key,
    required this.steps,
    required this.dueSoon,
    required this.onToggle,
    required this.onOpenPlan,
  });

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());
    final totalMinutes = steps.fold<int>(0, (sum, s) => sum + (s.milestone.minutes ?? 0));
    final isClear = steps.isEmpty && dueSoon.isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TODAY'S FOCUS",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.0,
                  ),
                ),
                if (totalMinutes > 0)
                  Text(
                    '~${_formatMinutes(totalMinutes)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isClear)
              Text("You're clear for today.", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
            ...dueSoon.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => onOpenPlan(t.id),
                    child: Row(
                      children: [
                        Icon(Icons.alarm, size: 20, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                '${t.courseCode} • Due ${DateFormat('E h:mm a').format(t.dueDate)}',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            ...steps.map((s) {
              final isLate = s.milestone.date.isBefore(today);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => onToggle(s),
                      child: Icon(Icons.circle_outlined, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => onOpenPlan(s.plan.taskId),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.milestone.title, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(
                              isLate
                                  ? '${s.plan.taskTitle} • from ${DateFormat('E, MMM d').format(s.milestone.date)}'
                                  : s.plan.taskTitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isLate ? theme.colorScheme.error : theme.colorScheme.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
