// Data models for a saved study plan and its daily milestones.

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class Milestone {
  final String id;
  String title;
  DateTime date;
  int? minutes;
  bool isDone;

  Milestone({
    required this.id,
    required this.title,
    required DateTime date,
    this.minutes,
    this.isDone = false,
  }) : date = dateOnly(date);

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'].toString(),
      title: json['title'] ?? 'Milestone',
      date: DateTime.parse(json['date']),
      minutes: (json['minutes'] as num?)?.toInt(),
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'minutes': minutes,
        'isDone': isDone,
      };
}

class StudyPlan {
  final String taskId;
  final String taskTitle;
  final String courseCode;
  final DateTime dueDate;
  final List<Milestone> milestones;

  StudyPlan({
    required this.taskId,
    required this.taskTitle,
    required this.courseCode,
    required this.dueDate,
    required this.milestones,
  });

  int get doneCount => milestones.where((m) => m.isDone).length;

  void sortByDate() {
    final order = {for (int i = 0; i < milestones.length; i++) milestones[i].id: i};
    milestones.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : order[a.id]!.compareTo(order[b.id]!);
    });
  }

  void reorder(int oldIndex, int newIndex) {
    final dates = milestones.map((m) => m.date).toList()..sort();
    final item = milestones.removeAt(oldIndex);
    milestones.insert(newIndex, item);
    for (int i = 0; i < milestones.length; i++) {
      milestones[i].date = dates[i];
    }
  }

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    return StudyPlan(
      taskId: json['taskId'].toString(),
      taskTitle: json['taskTitle'] ?? '',
      courseCode: json['courseCode'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      milestones: (json['milestones'] as List<dynamic>? ?? [])
          .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'courseCode': courseCode,
        'dueDate': dueDate.toIso8601String(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };
}
