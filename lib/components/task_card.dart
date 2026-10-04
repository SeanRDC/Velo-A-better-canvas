// Compact card for a single Canvas task showing a date block, its title, course, points,
// and how soon it is due (or how late it is).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  String _relativeDue(DateTime due, DateTime now) {
    final diff = due.difference(now);
    final span = diff.abs();

    String text;
    if (span.inMinutes < 60) {
      final minutes = span.inMinutes < 1 ? 1 : span.inMinutes;
      text = '$minutes min';
    } else if (span.inHours < 24) {
      text = span.inHours == 1 ? '1 hour' : '${span.inHours} hours';
    } else {
      text = span.inDays == 1 ? '1 day' : '${span.inDays} days';
    }

    return diff.isNegative ? '$text late' : 'in $text';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final due = task.dueDate.toLocal();

    final isOverdue = due.isBefore(now) && !task.isSubmitted;
    final isToday = !isOverdue && due.year == now.year && due.month == now.month && due.day == now.day;

    final Color blockColor;
    final Color blockTextColor;
    if (isOverdue) {
      blockColor = theme.colorScheme.error;
      blockTextColor = theme.colorScheme.onError;
    } else if (isToday) {
      blockColor = theme.colorScheme.primary;
      blockTextColor = theme.colorScheme.onPrimary;
    } else {
      blockColor = theme.colorScheme.secondary.withValues(alpha: 0.12);
      blockTextColor = theme.colorScheme.onSurface;
    }

    final statusColor = isOverdue ? theme.colorScheme.error : theme.colorScheme.secondary;
    final meta = task.points > 0 ? '${task.courseCode} · ${task.points} pts' : task.courseCode;

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 56,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(due).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: blockTextColor.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '${due.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: blockTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: statusColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${DateFormat('h:mm a').format(due)} · ${_relativeDue(due, now)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
