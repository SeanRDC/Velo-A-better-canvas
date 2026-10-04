// Data model representing a Canvas assignment, quiz, or discussion task, including whether it was submitted.
import 'course.dart';

class Task {
  final String id;
  final String title;
  final String courseId;
  final String courseName;
  final String courseCode;
  final DateTime dueDate;
  final int points;
  final String type;
  final bool isSubmitted;
  final String description;
  final bool isLocked;
  final List<dynamic> submissionTypes;

  Task({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.dueDate,
    required this.points,
    required this.type,
    this.isSubmitted = false,
    this.description = '',
    this.isLocked = false,
    this.submissionTypes = const [],
  });

  static bool submittedFromJson(Map<String, dynamic> json) {
    final submission = json['submission'];
    if (submission is Map) {
      if (submission['missing'] == true) return false;
      const doneStates = ['submitted', 'graded', 'pending_review'];
      return submission['submitted_at'] != null || doneStates.contains(submission['workflow_state']);
    }
    return json['has_submitted_submissions'] == true;
  }

  factory Task.fromCanvasJson(Map<String, dynamic> json, Course course) {
    return Task(
      id: json['id'].toString(),
      title: json['name'] ?? 'Untitled Assignment',
      courseId: course.id, 
      courseName: course.name,
      courseCode: course.courseCode,
      dueDate: json['due_at'] != null
          ? DateTime.parse(json['due_at']).toLocal()
          : DateTime.now().add(const Duration(days: 365)),
      points: (json['points_possible'] as num?)?.toInt() ?? 0,
      type: 'assignment',
      isSubmitted: submittedFromJson(json),
      description: json['description'] ?? '<p>No description provided.</p>',
      isLocked: json['locked_for_user'] as bool? ?? false,
      submissionTypes: json['submission_types'] ?? [],
    );
  }
}