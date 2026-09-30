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
  
  SharedPreferences? _cachedPrefs;
  Future<SharedPreferences> get _prefs async => _cachedPrefs ??= await SharedPreferences.getInstance();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  Future<String> _fetchWithCache(String url, String cacheKey) async {
    final prefs = await _prefs;
    final isOffline = prefs.getBool('isOffline') ?? false;
    
    if (isOffline) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return cachedData;
      } else {
        throw Exception('You are offline. No saved data available for this screen.');
      }
    }
    
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
             
      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, response.body);
        await prefs.setString('last_sync_time', DateTime.now().toIso8601String()); // Add this line
        return response.body;
      } else {
        throw Exception('Failed to load data from Canvas (Status: ${response.statusCode}).');
      }
    } catch (e) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return cachedData;
      } else {
        throw Exception('Network error. No connection and no saved data available.');
      }
    }
  }

  Future<Map<String, String>> fetchUserProfile() async {
    final url = '$_baseUrl/api/v1/users/self/profile';
    try {
      final body = await _fetchWithCache(url, 'cache_user_profile');
      final data = jsonDecode(body);
      
      String name = data['name'] ?? 'Unknown User';
      String email = data['primary_email'] ?? data['login_id'] ?? 'No email provided';
      
      String initials = 'U';
      final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        initials = parts.first[0].toUpperCase();
        if (parts.length > 1) {
          initials += parts.last[0].toUpperCase();
        }
      }
      
      return {
        'name': name,
        'email': email,
        'initials': initials,
        'program': 'Holy Angel University',
      };
    } catch (e) {
      // Offline/Error fallback
      return {
        'name': 'Student',
        'email': 'Loading...',
        'initials': 'S',
        'program': 'Holy Angel University',
      };
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
         
    final taskLists = await Future.wait(
      courses.map((course) async {
        try {
          return await fetchAssignmentsForCourse(course);
        } catch (_) {
          return <Task>[];
        }
      }),
    );

    for (final tasks in taskLists) {
      allTasks.addAll(tasks);
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

  Future<List<Map<String, dynamic>>> fetchConversations({String scope = 'inbox'}) async {
    final String scopeParam = (scope.isEmpty || scope == 'inbox') ? '' : 'scope=$scope&';
    final url = '$_baseUrl/api/v1/conversations?${scopeParam}per_page=50';
    final body = await _fetchWithCache(url, 'cache_inbox_conversations_$scope');
    
    final List<dynamic> data = jsonDecode(body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isOffline') ?? false) return;
    
    await http.put(
      Uri.parse('$_baseUrl/api/v1/conversations/$conversationId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'conversation': {'workflow_state': 'read'}}),
    );
  }

  Future<void> archiveConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isOffline') ?? false) {
      throw Exception('Cannot archive messages while offline.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/conversations/$conversationId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'conversation': {'workflow_state': 'archived'}}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to archive. Canvas returned: ${response.statusCode}');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isOffline') ?? false) {
      throw Exception('Cannot delete messages while offline.');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/conversations/$conversationId'),
      headers: _headers, // DELETE requests don't require JSON bodies
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete. Canvas returned: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchConversationDetail(String conversationId) async {
    final url = '$_baseUrl/api/v1/conversations/$conversationId';
    final body = await _fetchWithCache(url, 'cache_conv_$conversationId');
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> replyToConversation(String conversationId, String messageBody) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/conversations/$conversationId/add_message'),
      headers: _headers,
      body: {'body': messageBody},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send reply.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsersForCourse(String courseId) async {
    final url = '$_baseUrl/api/v1/courses/$courseId/users?per_page=100';
    final body = await _fetchWithCache(url, 'cache_users_$courseId');
    final List<dynamic> data = jsonDecode(body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> createConversation(String courseId, String recipientId, String subject, String messageBody) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/conversations'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'recipients': [recipientId],
        'subject': subject,
        'body': messageBody,
        'context_code': 'course_$courseId',
        'force_new': true,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message.');
    }
  }

  Future<String> buildTasksContext() async {
    final courses = await fetchActiveCourses();
    final buffer = StringBuffer();

    final results = await Future.wait(
      courses.map((course) async {
        try {
          final tasks = await fetchAssignmentsForCourse(course);
          final pending = tasks.where((t) => !t.isSubmitted).toList();
          return MapEntry(course.courseCode, pending);
        } catch (_) {
          return MapEntry(course.courseCode, <Task>[]);
        }
      }),
    );

    for (final entry in results) {
      if (entry.value.isNotEmpty) {
        buffer.writeln('${entry.key} Pending Tasks:');
        for (var t in entry.value) {
          buffer.writeln('- ${t.title} (Due: ${t.dueDate.toLocal()}, Points: ${t.points})');
        }
      }
    }

    return buffer.isEmpty ? 'No pending tasks.' : buffer.toString();
  }

  Future<String> buildGradesContext() async {
    final courses = await fetchActiveCourses();
    final buffer = StringBuffer();

    final results = await Future.wait(
      courses.map((course) async {
        try {
          final grades = await fetchGradesForCourse(course.id);
          return '${course.courseCode}: ${grades['current_score']}% (${grades['letter_grade']})';
        } catch (_) {
          return null;
        }
      }),
    );

    for (final line in results) {
      if (line != null) buffer.writeln(line);
    }

    return buffer.isEmpty ? 'No grades available.' : buffer.toString();
  }

  Future<String> buildAnnouncementsContext() async {
    final courses = await fetchActiveCourses();
    final buffer = StringBuffer();

    final results = await Future.wait(
      courses.map((course) async {
        try {
          final announcements = await fetchAnnouncementsForCourse(course.id);
          return MapEntry(course.courseCode, announcements.take(3).toList());
        } catch (_) {
          return MapEntry(course.courseCode, <Map<String, dynamic>>[]);
        }
      }),
    );

    for (final entry in results) {
      if (entry.value.isNotEmpty) {
        buffer.writeln('${entry.key} Announcements:');
        for (var a in entry.value) {
          buffer.writeln('- ${a['title']} (Posted: ${a['posted_at']})');
        }
      }
    }

    return buffer.isEmpty ? 'No recent announcements.' : buffer.toString();
  }

  Future<String> buildAssignmentDetailsContext(String targetTitle) async {
    try {
      final tasks = await fetchAllActiveTasks(); 
      
      // Find the closest match to what the AI requested
      final task = tasks.firstWhere(
        (t) => t.title.toLowerCase().contains(targetTitle.toLowerCase()),
        orElse: () => throw Exception('Assignment not found locally'),
      );

      // Fetch the specific assignment payload from Canvas
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/courses/${task.courseId}/assignments/${task.id}'),
        headers: _headers,
      );

      if (response.statusCode != 200) return "Could not fetch details from Canvas.";

      final data = jsonDecode(response.body);
      final String rawHtml = data['description'] ?? 'No description or instructions provided by the professor.';

      // Strip HTML tags and entities to save AI tokens
      final cleanText = rawHtml
          .replaceAll(RegExp(r'<[^>]*>'), ' ') 
          .replaceAll(RegExp(r'&[^;]+;'), ' ') 
          .replaceAll(RegExp(r'\s+'), ' ')     
          .trim();

      return "Instructions for ${task.title}: $cleanText";
      
    } catch (e) {
      return "Tell the user: I could not find the specific details for '$targetTitle'.";
    }
  }

  Future<String> buildInboxContext({String folder = 'inbox'}) async {
    try {
      final conversations = await fetchConversations(scope: folder);
      final List<Map<String, dynamic>> combined = List.from(conversations);

      // Only inject announcements if the AI is specifically looking at the main inbox
      if (folder == 'inbox') {
        final courses = await fetchActiveCourses();
        for (var course in courses) {
          try {
            final anns = await fetchAnnouncementsForCourse(course.id);
            for (var a in anns.take(3)) {
              combined.add({
                'id': 'ann_${a['id']}',
                'sender': a['user_name'] ?? 'Instructor (${course.courseCode})',
                'subject': '[${course.courseCode} Announcement] ${a['title'] ?? 'No Subject'}',
                'last_message': a['message'] ?? '',
                'last_message_at': a['posted_at'] ?? a['created_at'],
              });
            }
          } catch (_) {}
        }
      }

      if (combined.isEmpty) return 'The $folder folder is empty.';

      combined.sort((a, b) {
        final dA = DateTime.tryParse(a['last_message_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dB = DateTime.tryParse(b['last_message_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dB.compareTo(dA);
      });

      final buffer = StringBuffer();
      buffer.writeln('Recent Messages in $folder:');
      
      for (var item in combined.take(15)) {
        final id = item['id'];
        final subject = item['subject'] ?? 'No Subject';
        
        final List<dynamic> participants = item['participants'] ?? [];
        String partyInfo = '';
        
        if (folder == 'sent') {
          partyInfo = participants.isNotEmpty 
              ? 'To: ${participants.map((p) => p['name']).join(', ')}' 
              : 'To: Unknown';
        } else {
          String sender = item['sender'] ?? (participants.isNotEmpty ? participants[0]['name'] : 'Unknown');
          partyInfo = 'From: $sender';
        }

        String snippet = item['last_message'] ?? '';
        snippet = snippet.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (snippet.length > 100) snippet = '${snippet.substring(0, 100)}...';

        buffer.writeln('- [ID: $id] $partyInfo: "$subject" - $snippet');
      }
      buffer.writeln('\nTo read the full message thread of a specific item, use the get_thread_details tool using its ID.');
      return buffer.toString();
    } catch (e) {
      return 'Could not fetch messages for $folder.';
    }
  }

  Future<String> buildThreadContext(String threadId) async {
    if (threadId.startsWith('ann_')) {
      return 'This ID belongs to an announcement, not a direct message thread. You already have the snippet.';
    }
    try {
      final thread = await fetchConversationDetail(threadId);
      final messages = thread['messages'] as List<dynamic>? ?? [];
      final participants = thread['participants'] as List<dynamic>? ?? [];
      
      final participantNames = participants.map((p) => p['name']).join(', ');
      
      final buffer = StringBuffer();
      buffer.writeln('Full Thread: ${thread['subject'] ?? 'No Subject'}');
      buffer.writeln('Participants: $participantNames\n');
      
      for (var msg in messages) {
        final authorId = msg['author_id'];
        String authorName = 'Unknown';
        try {
          // Match the message author ID to the participant list
          authorName = participants.firstWhere((p) => p['id'] == authorId)['name'] ?? 'Unknown';
        } catch (_) {}
        
        String body = msg['body'] ?? '';
        body = body.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
        buffer.writeln('- At ${msg['created_at']} by $authorName:\n  $body\n');
      }
      return buffer.toString();
    } catch (e) {
      return 'Could not fetch full thread details.';
    }
  }
}