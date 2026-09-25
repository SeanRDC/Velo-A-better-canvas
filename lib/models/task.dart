// Data model representing a Canvas assignment, quiz, or discussion task.
import 'course.dart';

class Task {
  final String id;
  final String title;
  final String courseName;
  final String courseCode;
  final DateTime dueDate;
  final int points;
  final String type;
  final bool isSubmitted;

  Task({
    required this.id,
    required this.title,
    required this.courseName,
    required this.courseCode,
    required this.dueDate,
    required this.points,
    required this.type,
    this.isSubmitted = false,
  });

  factory Task.fromCanvasJson(Map<String, dynamic> json, Course course) {
    return Task(
      id: json['id'].toString(),
      title: json['name'] ?? 'Untitled Assignment',
      courseName: course.name,
      courseCode: course.courseCode,
      dueDate: json['due_at'] != null 
          ? DateTime.parse(json['due_at']).toLocal() 
          : DateTime.now().add(const Duration(days: 365)),
      points: (json['points_possible'] as num?)?.toInt() ?? 0,
      type: 'assignment',
      isSubmitted: json['has_submitted_submissions'] as bool? ?? false,
    );
  }
}