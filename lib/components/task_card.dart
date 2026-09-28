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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Improved time formatting for a larger card layout
    final dueString = DateFormat('MMM d, h:mm a').format(task.dueDate.toLocal());
    
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && !task.isSubmitted;
    final statusColor = isOverdue ? theme.colorScheme.error : theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        // The Classic Canvas Old Dashboard Left-Strip
        border: Border(
          left: BorderSide(
            color: isOverdue ? theme.colorScheme.error : theme.colorScheme.primary,
            width: 6,
          ),
          top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
          right: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
          bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased from 16 for better responsiveness
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.courseCode,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                  if (isOverdue)
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: theme.colorScheme.error),
                        const SizedBox(width: 4),
                        Text(
                          'Overdue',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else 
                    Text(
                      '${task.points} pts',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.title,
                // Upgraded to titleMedium to fix the "small" feeling
                style: theme.textTheme.titleMedium?.copyWith( 
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    'Due $dueString',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}