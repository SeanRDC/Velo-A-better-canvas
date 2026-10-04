// Handles all HTTP communication with the Canvas LMS REST API, with caching for offline use.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/task.dart';
import 'planner_store.dart';

class CanvasService {
  final String _baseUrl = dotenv.env['CANVAS_BASE_URL'] ?? '';
  SharedPreferences? _cachedPrefs;
  Future<SharedPreferences> get _prefs async => _cachedPrefs ??= await SharedPreferences.getInstance();

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxPages = 5;
  static const String _canvasHost = 'hau.instructure.com';

  static final Map<String, Future<String>> _inFlight = {};
  static final Map<String, DateTime> _refreshedAt = {};
  static const Duration _minRefreshGap = Duration(seconds: 30);

  static final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);
  static Timer? _notifyTimer;

  static DateTime? _freshReadsUntil;

  static int _sessionEpoch = 0;

  static void requestFresh() {
    _refreshedAt.clear();
    _freshReadsUntil = DateTime.now().add(const Duration(seconds: 10));
  }

  static void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 300), () => dataRevision.value++);
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await _prefs;
    final token = prefs.getString('canvas_api_token');
    if (token == null || token.isEmpty) {
      throw Exception('Not signed in to Canvas.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  String? _toBaseUrl(String absoluteUrl) {
    final uri = Uri.tryParse(absoluteUrl);
    if (uri == null) return null;

    final baseHost = Uri.tryParse(_baseUrl)?.host ?? '';
    if (uri.hasAuthority && uri.host != _canvasHost && (baseHost.isEmpty || uri.host != baseHost)) {
      return null;
    }
    return '$_baseUrl${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
  }

  String? _nextPageUrl(String? linkHeader) {
    if (linkHeader == null) return null;
    final match = RegExp(r'<([^>]+)>;\s*rel="next"').firstMatch(linkHeader);
    return match == null ? null : _toBaseUrl(match.group(1)!);
  }

  Future<String> _fetchPages(String url, {required bool paginate}) async {
    final headers = await _getHeaders();
    var response = await http.get(Uri.parse(url), headers: headers).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load data from Canvas (Status: ${response.statusCode}).');
    }
    if (!paginate) return response.body;

    String? next = _nextPageUrl(response.headers['link']);
    if (next == null) return response.body;

    final firstPage = jsonDecode(response.body);
    if (firstPage is! List) return response.body;

    final items = List<dynamic>.from(firstPage);
    for (int page = 1; page < _maxPages && next != null; page++) {
      response = await http.get(Uri.parse(next), headers: headers).timeout(_timeout);
      if (response.statusCode != 200) break;
      items.addAll(jsonDecode(response.body) as List<dynamic>);
      next = _nextPageUrl(response.headers['link']);
    }
    return jsonEncode(items);
  }

  Future<void> _writeCache(SharedPreferences prefs, String cacheKey, String body) async {
    try {
      await prefs.setString(cacheKey, body);
    } catch (_) {
      const detailPrefixes = ['cache_page_', 'cache_api_', 'cache_conv_'];
      final stale = prefs.getKeys().where((k) => detailPrefixes.any(k.startsWith)).toList();
      for (final key in stale) {
        await prefs.remove(key);
      }
      try {
        await prefs.setString(cacheKey, body);
      } catch (_) {}
    }
    try {
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<String> _fetchWithCache(
    String url,
    String cacheKey, {
    bool paginate = false,
    bool waitForNetwork = false,
  }) async {
    final prefs = await _prefs;
    final cachedData = prefs.getString(cacheKey);

    if (prefs.getBool('isOffline') ?? false) {
      if (cachedData != null) return cachedData;
      throw Exception('You are offline. No saved data available for this screen.');
    }

    final now = DateTime.now();
    final wantsFresh = _freshReadsUntil != null && now.isBefore(_freshReadsUntil!);

    if (cachedData != null && !waitForNetwork && !wantsFresh) {
      final last = _refreshedAt[cacheKey];
      if (last == null || now.difference(last) >= _minRefreshGap) {
        _download(url, cacheKey, cachedData, paginate).then((_) {}, onError: (_) {});
      }
      return cachedData;
    }

    try {
      return await _download(url, cacheKey, cachedData, paginate);
    } catch (e) {
      if (cachedData != null) return cachedData;
      throw Exception('Network error. No connection and no saved data available.');
    }
  }

  Future<String> _download(String url, String cacheKey, String? previous, bool paginate) {
    return _inFlight[cacheKey] ??= _downloadAndStore(url, cacheKey, previous, paginate).whenComplete(() {
      _inFlight.remove(cacheKey);
    });
  }

  Future<String> _downloadAndStore(String url, String cacheKey, String? previous, bool paginate) async {
    final epoch = _sessionEpoch;
    final body = await _fetchPages(url, paginate: paginate);

    if (epoch != _sessionEpoch) return body;

    _refreshedAt[cacheKey] = DateTime.now();
    await _writeCache(await _prefs, cacheKey, body);
    if (previous != null && previous != body) _scheduleNotify();
    return body;
  }

  void _markChanged() => requestFresh();

  Future<bool> isReachable() async {
    try {
      await http
          .get(Uri.parse('$_baseUrl/api/v1/courses?per_page=1'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    final cacheKeys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in cacheKeys) {
      await prefs.remove(key);
    }
    await prefs.remove('canvas_api_token');
    await prefs.remove('last_sync_time');
    await prefs.remove(PlannerStore.storageKey);

    _memProfile = null;
    _sessionEpoch++;
    _refreshedAt.clear();
    _freshReadsUntil = null;
    _notifyTimer?.cancel();
  }

  Future<bool> verifyAndSaveToken(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty) return false;

    try {
      final url = '$_baseUrl/api/v1/users/self/profile';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        await clearSession();
        final prefs = await _prefs;
        await prefs.setString('canvas_api_token', token);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String>? _memProfile;

  Future<Map<String, String>> fetchUserProfile() async {

    if (_memProfile != null) return _memProfile!;

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
      
      String programName = 'University Student';
      try {
        final host = Uri.parse(_baseUrl).host;
        final hostParts = host.split('.');
        if (hostParts.isNotEmpty && hostParts[0] != 'canvas') {
          programName = hostParts[0].toUpperCase();
        }
      } catch (_) {}

      String avatarUrl = (data['avatar_url'] ?? '').replaceAll('https://hau.instructure.com', '');
      String bio = data['bio'] ?? '';
      
      _memProfile = {
        'name': name,
        'email': email,
        'initials': initials,
        'program': programName,
        'avatar_url': avatarUrl,
        'bio': bio,
      };
      return _memProfile!;
    } catch (e) {
      return {
        'name': 'Student',
        'email': 'Loading...',
        'initials': 'S',
        'program': 'Canvas Student',
        'avatar_url': '',
        'bio': '',
      };
    }
  }

  Future<void> updateUserBio(String newBio) async {
    final prefs = await _prefs;
    if (prefs.getBool('isOffline') ?? false) {
      throw Exception('Cannot update profile while offline.');
    }
    
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/users/self/profile'),
      headers: await _getHeaders(),
      body: {'user[bio]': newBio},
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to update Canvas profile');
    }

    await prefs.remove('cache_user_profile');
    _memProfile = null;
    _markChanged();
  }

  Future<String> _fetchAssignmentsBody(String courseId) {
    final url = '$_baseUrl/api/v1/courses/$courseId/assignments?include[]=submission&per_page=100';
    return _fetchWithCache(url, 'cache_assignments_$courseId', paginate: true);
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
    final body = await _fetchAssignmentsBody(course.id);

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
    final enrollUrl = '$_baseUrl/api/v1/courses/$courseId/enrollments?user_id=self';

    final assignmentsBody = await _fetchAssignmentsBody(courseId);
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
        final body = await _fetchWithCache(url, 'cache_page_${courseId}_$pageUrl', waitForNetwork: true);
        return jsonDecode(body)['body'] ?? '';
      } 
      else if (apiUrl != null && (type.toLowerCase() == 'assignment' || type.toLowerCase() == 'discussion')) {
        final safeUrl = _toBaseUrl(apiUrl);
        if (safeUrl == null) return '';
        final body = await _fetchWithCache(safeUrl, 'cache_api_${Uri.parse(apiUrl).path}', waitForNetwork: true);
        final data = jsonDecode(body);
        return data['description'] ?? data['message'] ?? '';
      }
    } catch (e) {
      return '<p><em>Content is not available offline. Please connect to the internet to view this item.</em></p>';
    }
    return '';
  }

  Future<List<Map<String, dynamic>>> fetchRawAssignmentPayloads(String courseId) async {
    final body = await _fetchAssignmentsBody(courseId);

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
      headers: await _getHeaders(),
      body: {'conversation[workflow_state]': 'read'},
    ).timeout(_timeout);
    _markChanged();
  }

  Future<void> markAnnouncementAsRead(String courseId, String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isOffline') ?? false) return;

    await http.put(
      Uri.parse('$_baseUrl/api/v1/courses/$courseId/discussion_topics/$topicId/read'),
      headers: await _getHeaders(),
    ).timeout(_timeout);
    _markChanged();
  }

  Future<void> archiveConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isOffline') ?? false) {
      throw Exception('Cannot archive messages while offline.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/conversations/$conversationId'),
      headers: await _getHeaders(),
      body: jsonEncode({'conversation': {'workflow_state': 'archived'}}),
    ).timeout(_timeout);
    _markChanged();

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
      headers: await _getHeaders(),
    ).timeout(_timeout);
    _markChanged();

    if (response.statusCode != 200) {
      throw Exception('Failed to delete. Canvas returned: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchConversationDetail(String conversationId) async {
    final url = '$_baseUrl/api/v1/conversations/$conversationId';
    final body = await _fetchWithCache(url, 'cache_conv_$conversationId', waitForNetwork: true);
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> replyToConversation(String conversationId, String messageBody) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/conversations/$conversationId/add_message'),
      headers: await _getHeaders(),
      body: {'body': messageBody},
    ).timeout(_timeout);
    _markChanged();
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
      headers: await _getHeaders(),
      body: jsonEncode({
        'recipients': [recipientId],
        'subject': subject,
        'body': messageBody,
        'context_code': 'course_$courseId',
        'force_new': true,
      }),
    ).timeout(_timeout);
    _markChanged();
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
          return MapEntry(course, pending);
        } catch (_) {
          return MapEntry(course, <Task>[]);
        }
      }),
    );

    for (final entry in results) {
      if (entry.value.isNotEmpty) {
        buffer.writeln('${entry.key.courseCode} Pending Tasks:');
        for (var t in entry.value) {
          buffer.writeln('- ${t.title} (Due: ${t.dueDate.toLocal()}, Points: ${t.points}) [Link: velo://task?courseId=${entry.key.id}&taskId=${t.id}]');
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
          return MapEntry(course, announcements.take(3).toList());
        } catch (_) {
          return MapEntry(course, <Map<String, dynamic>>[]);
        }
      }),
    );

    for (final entry in results) {
      if (entry.value.isNotEmpty) {
        buffer.writeln('${entry.key.courseCode} Announcements:');
        for (var a in entry.value) {
          buffer.writeln('- ${a['title']} (Posted: ${a['posted_at']}) [Link: velo://announcements?courseId=${entry.key.id}]');
        }
      }
    }

    return buffer.isEmpty ? 'No recent announcements.' : buffer.toString();
  }

  Future<String> buildAssignmentDetailsContext(String targetTitle) async {
    try {
      final tasks = await fetchAllActiveTasks(); 
      
      final task = tasks.firstWhere(
        (t) => t.title.toLowerCase().contains(targetTitle.toLowerCase()),
        orElse: () => throw Exception('Assignment not found locally'),
      );

      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/courses/${task.courseId}/assignments/${task.id}'),
        headers: await _getHeaders(),
      ).timeout(_timeout);

      if (response.statusCode != 200) return "Could not fetch details from Canvas.";

      final data = jsonDecode(response.body);
      final String rawHtml = data['description'] ?? 'No description or instructions provided by the professor.';

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

      if (folder == 'inbox') {
        final courses = await fetchActiveCourses();
        final perCourse = await Future.wait(
          courses.map((course) async {
            try {
              final anns = await fetchAnnouncementsForCourse(course.id);
              return anns.take(3).map((a) => <String, dynamic>{
                'id': 'ann_${a['id']}',
                'sender': a['user_name'] ?? 'Instructor (${course.courseCode})',
                'subject': '[${course.courseCode} Announcement] ${a['title'] ?? 'No Subject'}',
                'last_message': a['message'] ?? '',
                'last_message_at': a['posted_at'] ?? a['created_at'],
              }).toList();
            } catch (_) {
              return <Map<String, dynamic>>[];
            }
          }),
        );
        for (final items in perCourse) {
          combined.addAll(items);
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

        buffer.writeln('- [ID: $id] $partyInfo: "$subject" - $snippet [Link: velo://conversation?threadId=$id]');
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