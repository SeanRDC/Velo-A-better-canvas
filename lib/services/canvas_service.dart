// Handles all HTTP REST communication with the Canvas LMS API with Offline Caching.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/task.dart';

class CanvasService {
  final String _baseUrl = dotenv.env['CANVAS_BASE_URL'] ?? '';
  final String _token = dotenv.env['CANVAS_API_TOKEN'] ?? '';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  /// Core Caching Logic: Routes requests to network or local storage
  Future<String> _fetchWithCache(String url, String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final isOffline = prefs.getBool('isOffline') ?? false;

    // 1. If Offline mode is explicitly enabled, pull from cache
    if (isOffline) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return cachedData;
      } else {
        throw Exception('You are offline. No saved data available for this screen.');
      }
    }

    // 2. If Online, attempt to hit the Canvas API
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      
      if (response.statusCode == 200) {
        // Save the successful payload to local storage for future offline use
        await prefs.setString(cacheKey, response.body);
        return response.body;
      } else {
        throw Exception('Failed to load data from Canvas (Status: ${response.statusCode}).');
      }
    } catch (e) {
      // 3. Fallback: If network drops unexpectedly but Offline toggle wasn't flipped
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return cachedData;
      } else {
        throw Exception('Network error. No connection and no saved data available.');
      }
    }
  }

  Future<List<Course>> fetchActiveCourses() async {
    final url = '$_baseUrl/api/v1/courses?enrollment_state=active&include[]=term&include[]=teachers&per_page=50';
    final body = await _fetchWithCache(url, 'cache_active_courses');
    
    final List<dynamic> data = jsonDecode(body);
    return data
        .map((json) => Course.fromJson(json))
        .where((course) => course.name != 'Unnamed Course')
        .toList();
  }

  Future<List<Task>> fetchAssignmentsForCourse(Course course) async {
    final url = '$_baseUrl/api/v1/courses/${course.id}/assignments?per_page=100';
    final body = await _fetchWithCache(url, 'cache_assignments_${course.id}');
    
    final List<dynamic> data = jsonDecode(body);
    return data.map((json) => Task.fromCanvasJson(json, course)).toList();
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
    final assignUrl = '$_baseUrl/api/v1/courses/$courseId/assignments?include[]=submission&per_page=100';
    final enrollUrl = '$_baseUrl/api/v1/courses/$courseId/enrollments?user_id=self';

    final assignmentsBody = await _fetchWithCache(assignUrl, 'cache_grades_assign_$courseId');
    final enrollmentsBody = await _fetchWithCache(enrollUrl, 'cache_grades_enroll_$courseId');

    final List<dynamic> assignmentsData = jsonDecode(assignmentsBody);
    final List<dynamic> enrollmentsData = jsonDecode(enrollmentsBody);

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
  }

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
    final url = '$_baseUrl/api/v1/courses/$courseId/modules?include[]=items&per_page=100';
    final body = await _fetchWithCache(url, 'cache_modules_$courseId');
    
    final List<dynamic> data = jsonDecode(body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncementsForCourse(String courseId) async {
    final url = '$_baseUrl/api/v1/courses/$courseId/discussion_topics?only_announcements=true&per_page=50';
    final body = await _fetchWithCache(url, 'cache_announcements_$courseId');
    
    final List<dynamic> data = jsonDecode(body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<String> fetchModuleItemHtml(String courseId, String type, String? pageUrl, String? apiUrl) async {
    try {
      if (type.toLowerCase() == 'page' && pageUrl != null) {
        final url = '$_baseUrl/api/v1/courses/$courseId/pages/$pageUrl';
        final body = await _fetchWithCache(url, 'cache_page_${courseId}_$pageUrl');
        return jsonDecode(body)['body'] ?? '';
      } 
      else if (apiUrl != null && (type.toLowerCase() == 'assignment' || type.toLowerCase() == 'discussion')) {
        final body = await _fetchWithCache(apiUrl, 'cache_api_${apiUrl.hashCode}');
        final data = jsonDecode(body);
        return data['description'] ?? data['message'] ?? '';
      }
    } catch (e) {
      return '<p><em>Content is not available offline. Please connect to the internet to view this item.</em></p>';
    }
    return '';
  }

  Future<List<Map<String, dynamic>>> fetchRawAssignmentPayloads(String courseId) async {
    final url = '$_baseUrl/api/v1/courses/$courseId/assignments?include[]=submission&per_page=100';
    final body = await _fetchWithCache(url, 'cache_raw_assignments_$courseId');
    
    final List<dynamic> data = jsonDecode(body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchConversations() async {
    // Fetches the user's Canvas inbox messages
    final url = '$_baseUrl/api/v1/conversations?per_page=50';
    final body = await _fetchWithCache(url, 'cache_inbox_conversations');
    
    final List<dynamic> data = jsonDecode(body);
    return data.cast<Map<String, dynamic>>();
  }
}