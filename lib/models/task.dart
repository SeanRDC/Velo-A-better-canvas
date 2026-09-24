// Data model representing a Canvas assignment, quiz, or discussion task.
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

  // Factory constructor to parse your mock JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      courseName: json['courseName'] as String,
      courseCode: json['courseCode'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      points: json['points'] as int,
      type: json['type'] as String,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
    );
  }
}