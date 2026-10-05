// Compact card for a single Canvas task showing its course image, title, course, points,
// and when it is due (or how late it is).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/task.dart';
import 'course_image.dart';

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

    final course = Course(
      id: task.courseId,
      name: task.courseName,
      courseCode: task.courseCode,
      imageUrl: task.courseImageUrl,
      colorHex: task.courseColorHex,
    );

    final Color statusColor;
    if (isOverdue) {
      statusColor = theme.colorScheme.error;
    } else if (isToday) {
      statusColor = theme.colorScheme.primary;
    } else {
      statusColor = theme.colorScheme.secondary;
    }
    final dueLabel = isToday ? 'Today' : DateFormat('MMM d').format(due);
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
              CourseImage(course: course, width: 56, height: 56, radius: 10),
              const SizedBox(width: 12),
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
                            '$dueLabel, ${DateFormat('h:mm a').format(due)} · ${_relativeDue(due, now)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: isOverdue || isToday ? FontWeight.bold : FontWeight.w500,
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
