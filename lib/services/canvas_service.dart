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
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses?enrollment_state=active&include[]=term&include[]=teachers&per_page=50'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Course.fromJson(json))
          .where((course) => course.name != 'Unnamed Course') 
          .toList();
    } else {
      throw Exception('Failed to load courses.');
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

  Future<Map<String, dynamic>> fetchGradesForCourse(String courseId) async {
    final assignmentsRes = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses/$courseId/assignments?include[]=submission&per_page=100'),
      headers: _headers,
    );

    final enrollmentsRes = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses/$courseId/enrollments?user_id=self'),
      headers: _headers,
    );

    if (assignmentsRes.statusCode == 200 && enrollmentsRes.statusCode == 200) {
      final List<dynamic> assignmentsData = jsonDecode(assignmentsRes.body);
      final List<dynamic> enrollmentsData = jsonDecode(enrollmentsRes.body);

      // Parse ALL items (graded and ungraded) with status flags
      final List<Map<String, dynamic>> gradedItems = [];
      for (var item in assignmentsData) {
        final submission = item['submission'];
        
        bool isLate = submission?['late'] ?? false;
        bool isMissing = submission?['missing'] ?? false;
        bool isExcused = submission?['excused'] ?? false;
        
        String? status;
        if (isExcused) {
          status = 'Excused';
        } else if (isMissing) {
          status = 'Missing';
        } else if (isLate) {
          status = 'Late';
        }

        gradedItems.add({
          'label': item['name'] ?? 'Unknown Assignment',
          'score': submission?['score'],
          'total': item['points_possible'] ?? 0,
          'status': status,
        });
      }

      num currentScore = 0;
      String letterGrade = 'N/A';
      
      if (enrollmentsData.isNotEmpty) {
        final grades = enrollmentsData.first['grades'];
        if (grades != null) {
          currentScore = grades['current_score'] ?? 0;
          letterGrade = grades['current_grade'] ?? _calculateLetterGrade(currentScore);
        }
      }

      return {
        'items': gradedItems,
        'current_score': currentScore,
        'letter_grade': letterGrade,
      };
    } else {
      throw Exception('Failed to load grades from Canvas.');
    }
  }

  // Fallback calculator if the instructor hasn't enabled letter grades in Canvas
  String _calculateLetterGrade(num score) {
    if (score >= 97) return 'A+';
    if (score >= 93) return 'A';
    if (score >= 90) return 'A-';
    if (score >= 87) return 'B+';
    if (score >= 83) return 'B';
    if (score >= 80) return 'B-';
    if (score >= 77) return 'C+';
    if (score >= 73) return 'C';
    if (score >= 70) return 'C-';
    if (score == 0) return 'N/A';
    return 'F';
  }

  Future<List<Map<String, dynamic>>> fetchModulesForCourse(String courseId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses/$courseId/modules?include[]=items&per_page=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load modules from Canvas.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncementsForCourse(String courseId) async {
    // Canvas stores announcements as discussion topics with a specific filter
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses/$courseId/discussion_topics?only_announcements=true&per_page=50'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load announcements from Canvas.');
    }
  }

  Future<String> fetchModuleItemHtml(String courseId, String type, String? pageUrl, String? apiUrl) async {
    if (type.toLowerCase() == 'page' && pageUrl != null) {
      final res = await http.get(Uri.parse('$_baseUrl/api/v1/courses/$courseId/pages/$pageUrl'), headers: _headers);
      if (res.statusCode == 200) return jsonDecode(res.body)['body'] ?? '';
    } 
    else if (apiUrl != null && (type.toLowerCase() == 'assignment' || type.toLowerCase() == 'discussion')) {
      final res = await http.get(Uri.parse(apiUrl), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['description'] ?? data['message'] ?? '';
      }
    }
    return ''; 
  }

  Future<List<Map<String, dynamic>>> fetchRawAssignmentPayloads(String courseId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses/$courseId/assignments?include[]=submission&per_page=100'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load assignments from Canvas.');
    }
  }
}