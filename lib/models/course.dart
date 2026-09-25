/// Data model representing a Canvas enrolled course.
class Course {
  final String id;
  final String name;
  final String courseCode;

  Course({
    required this.id,
    required this.name,
    required this.courseCode,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Course',
      courseCode: json['course_code'] ?? 'N/A',
    );
  }
}