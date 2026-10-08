// Checks that demo mode answers the app's Canvas and AI calls from mock data.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/services/canvas_service.dart';
import 'package:final_project/services/demo_backend.dart';
import 'package:final_project/services/demo_mode.dart';
import 'package:final_project/services/groq_service.dart';

void main() {
  late CanvasService canvas;

  setUp(() {
    dotenv.loadFromString(envString: 'CANVAS_BASE_URL=\nGROQ_API_KEY=', isOptional: true);
    SharedPreferences.setMockInitialValues({'canvas_api_token': 'demo'});
    DemoMode.client = buildDemoClient();
    CanvasService.requestFresh();
    canvas = CanvasService();
  });

  tearDown(() => DemoMode.client = null);

  test('only the /demo link turns demo mode on', () {
    expect(DemoMode.requestedBy(Uri.parse('https://velo-canvas-copilot.vercel.app/')), isFalse);
  });

  test('every course has tasks, grades, modules and announcements', () async {
    final courses = await canvas.fetchActiveCourses();
    expect(courses, hasLength(5));
    expect(courses.first.instructor, 'Prof. Maria Santos');
    expect(courses.first.colorHex, isNotEmpty);

    for (final course in courses) {
      expect(await canvas.fetchAssignmentsForCourse(course), isNotEmpty);
      expect((await canvas.fetchGradesForCourse(course.id))['current_score'], greaterThan(0));
      expect(await canvas.fetchAnnouncementsForCourse(course.id), isNotEmpty);
      expect(await canvas.fetchUsersForCourse(course.id), isNotEmpty);

      final modules = await canvas.fetchModulesForCourse(course.id);
      expect(modules, isNotEmpty);
      for (final item in modules.first['items'] as List) {
        if (item['type'] == 'SubHeader') continue;
        final html = await canvas.fetchModuleItemHtml(course.id, item['type'], item['page_url'], item['url']);
        expect(html, contains('<p>'), reason: item['title']);
      }
    }
  });

  test('the to-do feed has overdue, due-today and upcoming work', () async {
    final pending = (await canvas.fetchAllActiveTasks()).where((t) => !t.isSubmitted).toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysUntil(DateTime due) => DateTime(due.year, due.month, due.day).difference(today).inDays;

    expect(pending.where((t) => daysUntil(t.dueDate) < 0), isNotEmpty);
    expect(pending.where((t) => daysUntil(t.dueDate) == 0), isNotEmpty);
    expect(pending.where((t) => daysUntil(t.dueDate) > 0), isNotEmpty);
  });

  test('submitting, uploading and commenting change the mock submission', () async {
    expect((await canvas.fetchMySubmission('101', '2004'))['submitted_at'], isNull);

    final fileId = await canvas.uploadSubmissionFile('101', '2004', 'design.pdf', Uint8List.fromList([1, 2, 3]));
    await canvas.submitAssignment('101', '2004', type: 'online_upload', fileId: fileId, comment: 'Here it is.');
    await canvas.addSubmissionComment('101', '2004', 'One more note.');

    final submission = await canvas.fetchMySubmission('101', '2004');
    expect(submission['workflow_state'], 'submitted');
    expect(submission['submission_comments'], hasLength(2));

    final tasks = await canvas.fetchAllActiveTasks();
    expect(tasks.firstWhere((t) => t.id == '2004').isSubmitted, isTrue);
  });

  test('the inbox can be read, replied to, archived, composed and deleted', () async {
    final inbox = await canvas.fetchConversations();
    expect(inbox, hasLength(4));
    expect(await canvas.fetchUnreadInboxCount(), 4);

    final id = inbox.first['id'].toString();
    await canvas.markConversationAsRead(id);
    await canvas.replyToConversation(id, 'Thank you!');
    expect((await canvas.fetchConversationDetail(id))['messages'].first['body'], 'Thank you!');

    await canvas.archiveConversation(id);
    expect(await canvas.fetchConversations(), hasLength(3));
    expect(await canvas.fetchConversations(scope: 'archived'), hasLength(2));

    await canvas.createConversation('101', '2101', 'Hello', 'A new message');
    expect((await canvas.fetchConversations(scope: 'sent')).first['subject'], 'Hello');

    await canvas.deleteConversation(id);
    expect(await canvas.fetchConversations(scope: 'archived'), hasLength(1));
  });

  test('the assistant asks for a tool, then answers with links', () async {
    final groq = GroqService();
    final tools = [
      {'type': 'function', 'function': {'name': 'get_pending_tasks'}}
    ];
    final history = <Map<String, dynamic>>[
      {'role': 'user', 'content': 'What is due this week?'}
    ];

    final first = await groq.chat(messages: history, tools: tools);
    expect(first['tool_calls'][0]['function']['name'], 'get_pending_tasks');

    history.add({'role': 'tool', 'name': 'get_pending_tasks', 'content': await canvas.buildTasksContext()});
    final answer = (await groq.chat(messages: history, tools: tools))['content'] as String;
    expect(answer, contains('velo://task?courseId='));
    expect(answer, contains('Demo mode'));
  });

  test('Auto-Plan gets a JSON plan that fits before the deadline', () async {
    final message = await GroqService().chat(messages: [
      {'role': 'user', 'content': 'Task: Lab 3: Graph Traversal. Course: 6DSALG. Worth 50 points. Total time until due: 4 days. Instructions: x'}
    ]);
    final List<dynamic> plan = jsonDecode(message['content']);
    expect(plan, hasLength(4));
    expect(plan.every((step) => step['dateOffset'] >= 0 && step['dateOffset'] <= 4), isTrue);
  });
}
