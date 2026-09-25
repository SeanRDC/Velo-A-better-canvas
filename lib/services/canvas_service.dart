// Handles all HTTP REST communication with the Canvas LMS API.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/course.dart';
import '../models/task.dart';

class CanvasService {
  final String _baseUrl = dotenv.env['CANVAS_BASE_URL'] ?? '';
  final String _token = dotenv.env['CANVAS_API_TOKEN'] ?? '';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  Future<List<Course>> fetchActiveCourses() async {
    if (_token.isEmpty || _baseUrl.isEmpty) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses?enrollment_state=active&per_page=50'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .where((json) => json['id'] != null && json['name'] != null)
          .map((json) => Course.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load courses: ${response.statusCode}');
    }
  }

  Future<List<Task>> fetchAssignmentsForCourse(Course course) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses/${course.id}/assignments?per_page=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromCanvasJson(json, course)).toList();
    } else {
      throw Exception('Failed to load assignments for ${course.courseCode}');
    }
  }
  
  Future<List<Task>> fetchAllActiveTasks() async {
    final courses = await fetchActiveCourses();
    final List<Task> allTasks = [];
    
    for (final course in courses) {
      try {
        final tasks = await fetchAssignmentsForCourse(course);
        allTasks.addAll(tasks);
      } catch (e) {
        continue;
      }
    }
    
    allTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return allTasks;
  }
}