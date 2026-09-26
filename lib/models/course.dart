class Course {
  final String id;
  final String name;
  final String courseCode;
  final String instructor;
  final String term;

  Course({
    required this.id,
    required this.name,
    required this.courseCode,
    this.instructor = 'Instructor unassigned',
    this.term = 'Current Term',
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    String parsedInstructor = 'Instructor unassigned';
    if (json['teachers'] != null && (json['teachers'] as List).isNotEmpty) {
      parsedInstructor = json['teachers'][0]['display_name'] ?? 'Instructor unassigned';
    }

    String parsedTerm = 'Current Term';
    if (json['term'] != null) {
      parsedTerm = json['term']['name'] ?? 'Current Term';
    }

    return Course(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unnamed Course',
      courseCode: json['course_code'] ?? 'Unknown Code',
      instructor: parsedInstructor,
      term: parsedTerm,
    );
  }
}