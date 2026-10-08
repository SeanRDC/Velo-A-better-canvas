// The mock Canvas and AI backend behind demo mode. It answers the same endpoints the app calls
// on Canvas, from made-up data held in memory, so every screen works without an account.
// Changes made in the demo (submissions, comments, messages) last until the page is reloaded.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';

http.Client buildDemoClient() {
  final backend = _DemoBackend();
  return MockClient(backend.handle);
}

const int _selfId = 1001;
const String _selfName = 'Alex Reyes';

class _DemoBackend {
  final DateTime _now = DateTime.now();
  int _nextId = 9000;

  late final Map<String, dynamic> _profile = {
    'id': _selfId,
    'name': _selfName,
    'primary_email': 'alex.reyes@student.velo.demo',
    'login_id': 'alex.reyes',
    'avatar_url': '',
    'bio': 'Third-year IT student. This is a demo profile with mock data.',
  };

  late final List<Map<String, dynamic>> _courses = [
    _course(101, 'Applications Development and Emerging Technologies', '6ADET', 'Prof. Maria Santos'),
    _course(102, 'Data Structures and Algorithms', '6DSALG', 'Prof. Daniel Cruz'),
    _course(103, 'Human-Computer Interaction', '6HCI', 'Prof. Liza Mendoza'),
    _course(104, 'Information Assurance and Security', '6IAS', 'Prof. Ramon Garcia'),
    _course(105, 'Ethics for IT Professionals', '6ETHICS', 'Prof. Grace Lim'),
  ];

  static const Map<String, String> _colors = {
    'course_101': '#3F6C8F',
    'course_102': '#5B7F5E',
    'course_103': '#8C5A6B',
    'course_104': '#7A6A9E',
    'course_105': '#A9703F',
  };

  static const Map<int, double> _courseScores = {101: 92.7, 102: 94.0, 103: 88.0, 104: 90.0, 105: 90.0};

  late final List<Map<String, dynamic>> _assignments = [
    _assignment(2001, 101, 'Project Proposal', -21, 50, ['online_upload'],
        'Write a one-page proposal for the app you will build this term.',
        ['The problem and who has it', 'The three features you commit to', 'What is out of scope'],
        score: 47, comment: 'Clear problem statement. Narrow the scope of the AI feature a little.'),
    _assignment(2002, 101, 'Wireframes and Mockup', -12, 100, ['online_upload', 'online_url'],
        'Design the main screens of your app before writing any code.',
        ['Low-fidelity wireframes for every screen', 'A high-fidelity mockup of the home screen', 'A screen flow diagram'],
        score: 92, comment: 'Strong visual hierarchy. Check the contrast of the secondary text.', reply: 'Thank you, I will fix the contrast in the next version.'),
    _assignment(2003, 101, 'Week 3 Progress Report', -2, 40, ['online_text_entry'],
        'Report what you built this week and what is blocking you.',
        ['What works now', 'What changed from the plan', 'What you will do next week'],
        missing: true),
    _assignment(2004, 101, 'Design System Documentation', 0, 60, ['online_upload', 'online_text_entry'],
        'Document the colors, type, spacing and components your app uses.',
        ['Color and type tokens', 'Spacing and radius scale', 'Screenshots of each reusable component']),
    _assignment(2005, 101, 'Final App Demo Video', 6, 100, ['online_url'],
        'Record a three to five minute walkthrough of your finished app.',
        ['Show every feature in your proposal', 'Narrate what happens on screen', 'Submit a link anyone in class can open']),
    _assignment(2006, 101, 'Final Project Submission', 13, 200, ['online_upload', 'online_url'],
        'Submit your finished app with its repository and documentation.',
        ['A link to the live app or a build', 'The repository with a complete README', 'The AI usage record']),
    _assignment(2011, 102, 'Lab 1: Linked Lists', -18, 50, ['online_upload'],
        'Implement a singly linked list with insert, delete and reverse.',
        ['Source file with comments', 'Sample output for each operation'],
        score: 44, late: true, comment: 'Correct, but submitted a day late. Reverse could be done in one pass.'),
    _assignment(2012, 102, 'Lab 2: Stacks and Queues', -9, 50, ['online_upload'],
        'Build a stack and a queue, then use them to check balanced brackets.',
        ['Stack and queue classes', 'The bracket checker with five test cases'],
        score: 50, comment: 'Perfect score. Clean and readable.'),
    _assignment(2013, 102, 'Problem Set: Binary Search Trees', 1, 80, ['online_upload'],
        'Answer six problems on insertion, deletion and traversal of binary search trees.',
        ['Worked solutions for all six problems', 'The time complexity of each operation'],
        extensions: ['pdf', 'docx']),
    _assignment(2014, 102, 'Lab 3: Graph Traversal', 4, 50, ['online_upload'],
        'Implement breadth-first and depth-first search on an adjacency list.',
        ['Both traversals in one source file', 'Output for the sample graph in the handout']),
    _assignment(2015, 102, 'Midterm Reviewer Reflection', 9, 20, ['online_text_entry'],
        'Write a short reflection on the topics you find hardest before the midterm.',
        ['Two topics you are confident in', 'Two topics you need to review, and your plan']),
    _assignment(2021, 103, 'Heuristic Evaluation', -14, 100, ['online_upload'],
        'Evaluate an existing app against the ten usability heuristics.',
        ['At least eight findings with screenshots', 'A severity rating for each finding'],
        score: 88, comment: 'Good findings. Severity ratings need a sentence of justification each.'),
    _assignment(2022, 103, 'User Interview Summary', -4, 50, ['online_upload', 'online_text_entry'],
        'Summarize what you learned from interviewing three target users.',
        ['Who you interviewed, without names', 'Three patterns you noticed', 'One thing that surprised you'],
        submitted: true),
    _assignment(2023, 103, 'Usability Test Plan', 2, 75, ['online_upload', 'online_text_entry'],
        'Plan a usability test for your prototype.',
        ['Five tasks for participants', 'What you will measure', 'Your consent script']),
    _assignment(2024, 103, 'High-Fidelity Prototype', 11, 150, ['online_url'],
        'Build a clickable prototype of your main user flow.',
        ['A share link to the prototype', 'At least six connected screens']),
    _assignment(2031, 104, 'Quiz 1 Reflection', -10, 30, ['online_text_entry'],
        'Reflect on the items you missed in Quiz 1.',
        ['Each missed item and the correct answer', 'Why the correct answer is right'],
        score: 27, comment: 'Thoughtful corrections.'),
    _assignment(2032, 104, 'Threat Model Worksheet', 3, 60, ['online_upload'],
        'Complete a threat model for a small web application.',
        ['Assets and trust boundaries', 'Threats listed by category', 'A mitigation for each threat']),
    _assignment(2033, 104, 'Case Study: Data Breach Response', 8, 100, ['online_upload', 'online_text_entry'],
        'Analyze how an organization responded to a data breach.',
        ['A timeline of the incident', 'What the response got right and wrong', 'Three recommendations']),
    _assignment(2034, 104, 'Security Audit Report', 20, 150, ['online_upload'],
        'Audit a sample system and report your findings.',
        ['Scope and method', 'Findings ranked by risk', 'Recommended fixes'],
        locked: true),
    _assignment(2041, 105, 'Reflection Paper 1', -16, 50, ['online_upload'],
        'Reflect on a professional dilemma from the first module.',
        ['The dilemma in your own words', 'The principles in tension', 'What you would do'],
        score: 45, comment: 'Well argued. Cite the code of ethics directly next time.'),
    _assignment(2042, 105, 'Discussion: AI and Academic Honesty', 5, 30, ['online_text_entry'],
        'Take a position on how students should disclose AI assistance.',
        ['Your position in one paragraph', 'One counterargument and your reply']),
    _assignment(2043, 105, 'Position Paper: Data Privacy', 15, 100, ['online_upload'],
        'Argue for or against a proposed data privacy rule.',
        ['A clear thesis', 'Three supporting arguments with sources', 'A conclusion']),
  ];

  late final Map<int, List<Map<String, dynamic>>> _announcements = {
    101: [
      _announcement(3001, 'Final demo schedule is posted', 1, 'Prof. Maria Santos', unread: true,
          '<p>The final demo schedule is now in Module 3. Each student has <strong>seven minutes</strong>: five to present and two for questions.</p><p>Please check your slot and tell me by Friday if you have a conflict.</p>'),
      _announcement(3002, 'Reminder: keep your AI usage record up to date', 6, 'Prof. Maria Santos',
          '<p>Your AI usage record is part of the final submission. Log each use as you go:</p><ul><li>what you asked for</li><li>what you kept and what you changed</li><li>the commit it went into</li></ul>'),
    ],
    102: [
      _announcement(3011, 'Midterm coverage', 2, 'Prof. Daniel Cruz', unread: true,
          '<p>The midterm covers linked lists, stacks, queues and binary search trees. Graphs are <em>not</em> included.</p><p>A reviewer is posted under Module 2.</p>'),
    ],
    103: [
      _announcement(3021, 'Guest talk on accessibility this week', 3, 'Prof. Liza Mendoza',
          '<p>We have a guest speaker this week on designing for screen readers. Attendance counts as class participation.</p>'),
      _announcement(3022, 'Prototype tool accounts', 9, 'Prof. Liza Mendoza',
          '<p>Use the education plan for your prototype tool. It is free for students and removes the three-file limit.</p>'),
    ],
    104: [
      _announcement(3031, 'No class on Thursday', 4, 'Prof. Ramon Garcia',
          '<p>There is no class on Thursday. Use the time to finish the Threat Model Worksheet.</p>'),
    ],
    105: [
      _announcement(3041, 'Position paper topics', 5, 'Prof. Grace Lim',
          '<p>The list of approved topics for the position paper is posted. You may propose your own topic by message.</p>'),
    ],
  };

  late final List<Map<String, dynamic>> _conversations = [
    _conversation(4001, 'inbox', 'Feedback on your wireframes', '6ADET', 2001, 'Prof. Maria Santos', unread: true, [
      _message(2001, 0.2, 'Hi Alex, your wireframes are in good shape. Before the final demo, please make sure the empty states are designed too. See me after class if you want to walk through them.'),
    ]),
    _conversation(4002, 'inbox', 'Group meeting for the usability test', '6HCI', 2101, 'Bea Navarro', unread: true, [
      _message(2101, 0.8, 'Sounds good. I will bring the consent forms. Can you prepare the task list?'),
      _message(_selfId, 1.0, 'Yes, Wednesday after lunch works for me. Library, second floor?'),
      _message(2101, 1.2, 'Hi! Are you free on Wednesday to plan the usability test?'),
    ]),
    _conversation(4003, 'inbox', 'Lab 1 late submission', '6DSALG', 2002, 'Prof. Daniel Cruz', [
      _message(2002, 16, 'Noted, Alex. I have applied the standard late deduction. Please submit on time for the next labs.'),
      _message(_selfId, 17, 'Good day, Professor. I submitted Lab 1 a day late because of a power interruption. I apologize for the delay.'),
    ]),
    _conversation(4004, 'inbox', 'Reviewer for the midterm', '6DSALG', 2102, 'Carlo Dizon', [
      _message(2102, 3, 'I made a shared reviewer for the midterm. Want me to add you so we can split the topics?'),
    ]),
    _conversation(4005, 'sent', 'Question about the position paper topic', '6ETHICS', 2005, 'Prof. Grace Lim', [
      _message(_selfId, 2, 'Good day, Professor. May I write my position paper on consent in learning analytics? It is not on the approved list.'),
    ]),
    _conversation(4006, 'archived', 'Welcome to 6IAS', '6IAS', 2004, 'Prof. Ramon Garcia', [
      _message(2004, 40, 'Welcome to Information Assurance and Security. The syllabus and the grading breakdown are in Module 1.'),
    ]),
  ];

  static const Map<int, List<(int, String)>> _classmates = {
    101: [(2001, 'Prof. Maria Santos'), (2101, 'Bea Navarro'), (2102, 'Carlo Dizon'), (2103, 'Dana Ocampo')],
    102: [(2002, 'Prof. Daniel Cruz'), (2102, 'Carlo Dizon'), (2104, 'Enzo Pineda'), (2105, 'Faith Aquino')],
    103: [(2003, 'Prof. Liza Mendoza'), (2101, 'Bea Navarro'), (2103, 'Dana Ocampo'), (2106, 'Gio Salazar')],
    104: [(2004, 'Prof. Ramon Garcia'), (2104, 'Enzo Pineda'), (2105, 'Faith Aquino'), (2107, 'Hana Villanueva')],
    105: [(2005, 'Prof. Grace Lim'), (2103, 'Dana Ocampo'), (2106, 'Gio Salazar'), (2107, 'Hana Villanueva')],
  };

  // Module outlines per course: each module is its name and the titles of its lesson pages.
  static const Map<int, List<(String, List<String>)>> _moduleOutlines = {
    101: [
      ('Module 1: Planning your app', ['Choosing a problem worth solving', 'Writing a project proposal']),
      ('Module 2: Design before code', ['Wireframes and screen flow', 'Building a design system']),
      ('Module 3: Shipping', ['Deploying a Flutter web app', 'Recording a demo video']),
    ],
    102: [
      ('Module 1: Linear structures', ['Linked lists', 'Stacks and queues']),
      ('Module 2: Trees', ['Binary search trees', 'Tree traversal']),
      ('Module 3: Graphs', ['Representing graphs', 'Breadth-first and depth-first search']),
    ],
    103: [
      ('Module 1: Evaluating interfaces', ['The ten usability heuristics', 'Running a heuristic evaluation']),
      ('Module 2: Learning from users', ['Interviewing users', 'Planning a usability test']),
      ('Module 3: Prototyping', ['From wireframe to prototype']),
    ],
    104: [
      ('Module 1: Foundations', ['Confidentiality, integrity and availability', 'Thinking like an attacker']),
      ('Module 2: Threat modeling', ['Drawing trust boundaries', 'Ranking threats by risk']),
      ('Module 3: Incident response', ['Responding to a data breach']),
    ],
    105: [
      ('Module 1: Professional responsibility', ['Codes of ethics in computing', 'Working through a dilemma']),
      ('Module 2: Data and privacy', ['Consent and data privacy', 'AI and academic honesty']),
    ],
  };

  String _at(num daysFromNow) =>
      _now.add(Duration(minutes: (daysFromNow * 24 * 60).round())).toUtc().toIso8601String();

  // Deadlines fall at 11:59 PM, so "due today" stays true for the whole day.
  String _dueAt(int daysFromNow) =>
      DateTime(_now.year, _now.month, _now.day + daysFromNow, 23, 59).toUtc().toIso8601String();

  Map<String, dynamic> _course(int id, String name, String code, String teacher) => {
        'id': id,
        'name': name,
        'course_code': code,
        'teachers': [
          {'display_name': teacher}
        ],
        'term': {'name': '1st Semester'},
        'image_download_url': '',
      };

  Map<String, dynamic> _assignment(
    int id,
    int courseId,
    String name,
    int dueInDays,
    int points,
    List<String> types,
    String brief,
    List<String> requirements, {
    num? score,
    String? comment,
    String? reply,
    bool submitted = false,
    bool late = false,
    bool missing = false,
    bool locked = false,
    List<String>? extensions,
  }) {
    final done = submitted || score != null;
    final teacherId = _classmates[courseId]!.first.$1;
    final teacherName = _classmates[courseId]!.first.$2;
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'description': '<p>$brief</p><p><strong>What to submit</strong></p>'
          '<ul>${requirements.map((r) => '<li>$r</li>').join()}</ul>'
          '<p>Check the rubric before you submit. Late work loses ten percent per day.</p>',
      'due_at': _dueAt(dueInDays),
      'points_possible': points,
      'submission_types': types,
      'allowed_extensions': ?extensions,
      'locked_for_user': locked,
      if (locked) 'lock_explanation': 'This assignment is locked until the previous module is completed.',
      'html_url': '',
      'has_submitted_submissions': done,
      'submission': {
        'id': id + 50000,
        'assignment_id': id,
        'user_id': _selfId,
        'workflow_state': score != null ? 'graded' : (submitted ? 'submitted' : 'unsubmitted'),
        'submitted_at': done ? _at(dueInDays - (late ? -1 : 1)) : null,
        'submission_type': done ? types.first : null,
        'score': score,
        'grade': score?.toString(),
        'late': late,
        'missing': missing,
        'excused': false,
        'submission_comments': [
          if (comment != null) _comment(teacherId, teacherName, comment, _at(dueInDays + 3)),
          if (reply != null) _comment(_selfId, _selfName, reply, _at(dueInDays + 3.5)),
        ],
      },
    };
  }

  Map<String, dynamic> _comment(int authorId, String authorName, String text, String createdAt) => {
        'id': _nextId++,
        'author_id': authorId,
        'author_name': authorName,
        'comment': text,
        'created_at': createdAt,
      };

  Map<String, dynamic> _announcement(int id, String title, num daysAgo, String author, String html, {bool unread = false}) => {
        'id': id,
        'title': title,
        'message': html,
        'posted_at': _at(-daysAgo),
        'created_at': _at(-daysAgo),
        'user_name': author,
        'read_state': unread ? 'unread' : 'read',
        'discussion_subentry_count': 0,
        'attachments': [],
      };

  Map<String, dynamic> _message(int authorId, num daysAgo, String body) => {
        'id': _nextId++,
        'author_id': authorId,
        'created_at': _at(-daysAgo),
        'body': body,
        'attachments': [],
      };

  // Messages are listed newest first, the way Canvas returns them.
  Map<String, dynamic> _conversation(
    int id,
    String folder,
    String subject,
    String courseCode,
    int otherId,
    String otherName,
    List<Map<String, dynamic>> messages, {
    bool unread = false,
  }) =>
      {
        'id': id,
        'folder': folder,
        'subject': subject,
        'workflow_state': unread ? 'unread' : 'read',
        'context_name': courseCode,
        'participants': [
          {'id': otherId, 'name': otherName},
          {'id': _selfId, 'name': _selfName},
        ],
        'messages': messages,
      };

  Map<String, dynamic> _conversationSummary(Map<String, dynamic> c) {
    final List<dynamic> messages = c['messages'];
    return {
      for (final entry in c.entries)
        if (entry.key != 'messages' && entry.key != 'folder') entry.key: entry.value,
      'last_message': messages.isEmpty ? '' : messages.first['body'],
      'last_message_at': messages.isEmpty ? _at(0) : messages.first['created_at'],
      'message_count': messages.length,
    };
  }

  Map<String, dynamic> _conversationDetail(Map<String, dynamic> c) => {
        ..._conversationSummary(c),
        'messages': c['messages'],
      };

  static String _slug(String title) => title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  List<Map<String, dynamic>> _modulesFor(int courseId) {
    final outline = _moduleOutlines[courseId] ?? const [];
    final assignments = _assignments.where((a) => a['course_id'] == courseId).toList();
    final perModule = (assignments.length / outline.length).ceil();
    int itemId = courseId * 1000;

    return [
      for (int m = 0; m < outline.length; m++)
        {
          'id': courseId * 10 + m,
          'name': outline[m].$1,
          'items': [
            {'id': itemId++, 'title': 'Lessons', 'type': 'SubHeader', 'indent': 0},
            for (final title in outline[m].$2)
              {'id': itemId++, 'title': title, 'type': 'Page', 'page_url': _slug(title), 'html_url': '', 'indent': 1},
            {'id': itemId++, 'title': 'Requirements', 'type': 'SubHeader', 'indent': 0},
            for (final a in assignments.skip(m * perModule).take(perModule))
              {
                'id': itemId++,
                'title': a['name'],
                'type': 'Assignment',
                'url': '/api/v1/courses/$courseId/assignments/${a['id']}',
                'html_url': '',
                'indent': 1,
              },
          ],
        },
    ];
  }

  Map<String, dynamic>? _pageFor(int courseId, String slug) {
    for (final module in _moduleOutlines[courseId] ?? const <(String, List<String>)>[]) {
      for (final title in module.$2) {
        if (_slug(title) != slug) continue;
        final topic = title.toLowerCase();
        return {
          'title': title,
          'body': '<h2>$title</h2>'
              '<p>This lesson introduces $topic and how it connects to the requirements in <strong>${module.$1}</strong>.</p>'
              '<h3>Learning outcomes</h3>'
              '<ul><li>Explain the main ideas behind $topic in your own words.</li>'
              '<li>Apply them to a small, concrete example.</li>'
              '<li>Recognize the most common mistakes and how to avoid them.</li></ul>'
              '<h3>Before the next class</h3>'
              '<p>Read the lesson, then write down one question to bring to class. '
              'The requirement for this module builds directly on this material.</p>'
              '<p><em>This is sample lesson content written for the Velo demo.</em></p>',
        };
      }
    }
    return null;
  }

  Map<String, dynamic>? _findAssignment(String id) {
    for (final a in _assignments) {
      if (a['id'].toString() == id) return a;
    }
    return null;
  }

  Map<String, dynamic>? _findConversation(String id) {
    for (final c in _conversations) {
      if (c['id'].toString() == id) return c;
    }
    return null;
  }

  static http.Response _json(Object? data, [int status = 200]) => http.Response(
        jsonEncode(data),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  static final http.Response _notFound = _json({'message': 'Not found in the demo.'}, 404);

  Future<http.Response> handle(http.Request request) async {
    // A short pause, so loading states show the way they do against the real Canvas.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final path = request.url.path;
    if (path.endsWith('/api/groq') || path.endsWith('/chat/completions')) return _chat(request);

    final apiAt = path.indexOf('/api/v1/');
    if (apiAt == -1) return _notFound;
    final parts = path.substring(apiAt + '/api/v1/'.length).split('/').where((p) => p.isNotEmpty).toList();

    try {
      return _route(request, parts) ?? _notFound;
    } catch (_) {
      return _json({'message': 'The demo could not answer this request.'}, 500);
    }
  }

  http.Response? _route(http.Request request, List<String> parts) {
    final method = request.method;
    if (parts.isEmpty) return null;

    if (parts[0] == 'users' && parts.length == 3 && parts[1] == 'self') {
      if (parts[2] == 'colors') return _json({'custom_colors': _colors});
      if (parts[2] == 'profile') {
        if (method == 'PUT') _profile['bio'] = request.bodyFields['user[bio]'] ?? '';
        return _json(_profile);
      }
    }

    if (parts[0] == 'demo-upload') return _json({'id': _nextId++}, 201);

    if (parts[0] == 'conversations') return _routeConversations(request, parts);

    if (parts[0] != 'courses') return null;
    if (parts.length == 1) return _json(_courses);

    final courseId = int.tryParse(parts[1]);
    if (courseId == null || !_courseScores.containsKey(courseId)) return null;
    if (parts.length == 2) return null;

    switch (parts[2]) {
      case 'enrollments':
        return _json([
          {
            'user_id': _selfId,
            'grades': {'current_score': _courseScores[courseId], 'current_grade': null},
          }
        ]);
      case 'modules':
        return _json(_modulesFor(courseId));
      case 'pages':
        final page = parts.length > 3 ? _pageFor(courseId, parts[3]) : null;
        return page == null ? null : _json(page);
      case 'users':
        return _json([
          for (final (id, name) in _classmates[courseId]!) {'id': id, 'name': name}
        ]);
      case 'discussion_topics':
        final topics = _announcements[courseId] ?? [];
        if (parts.length == 3) return _json(topics);
        if (method == 'PUT' && parts.length == 5 && parts[4] == 'read') {
          for (final topic in topics) {
            if (topic['id'].toString() == parts[3]) topic['read_state'] = 'read';
          }
          return http.Response('', 204);
        }
        return null;
      case 'assignments':
        return _routeAssignments(request, courseId, parts.sublist(3));
    }
    return null;
  }

  http.Response? _routeAssignments(http.Request request, int courseId, List<String> rest) {
    final method = request.method;
    if (rest.isEmpty) {
      return _json(_assignments.where((a) => a['course_id'] == courseId).toList());
    }

    final assignment = _findAssignment(rest[0]);
    if (assignment == null) return null;
    final Map<String, dynamic> submission = assignment['submission'];
    final List<dynamic> comments = submission['submission_comments'];

    void addComment(String? text) {
      if (text == null || text.trim().isEmpty) return;
      comments.add(_comment(_selfId, _selfName, text.trim(), _at(0)));
    }

    if (rest.length == 1) return _json(assignment);
    if (rest[1] != 'submissions') return null;

    // POST .../submissions hands the work in.
    if (rest.length == 2 && method == 'POST') {
      final fields = request.bodyFields;
      assignment['has_submitted_submissions'] = true;
      submission
        ..['workflow_state'] = 'submitted'
        ..['submitted_at'] = _at(0)
        ..['submission_type'] = fields['submission[submission_type]']
        ..['missing'] = false;
      addComment(fields['comment[text_comment]']);
      return _json(submission, 201);
    }

    if (rest.length == 3 && rest[2] == 'self') {
      if (method == 'PUT') addComment(request.bodyFields['comment[text_comment]']);
      return _json(submission);
    }

    // The first step of a file upload: Canvas answers with where to send the bytes.
    if (rest.length == 4 && rest[3] == 'files' && method == 'POST') {
      return _json({'upload_url': '/api/v1/demo-upload', 'upload_params': {}, 'file_param': 'file'});
    }
    return null;
  }

  http.Response? _routeConversations(http.Request request, List<String> parts) {
    final method = request.method;

    if (parts.length == 1) {
      if (method == 'POST') {
        final Map<String, dynamic> body = jsonDecode(request.body);
        final recipientId = int.tryParse((body['recipients'] as List).first.toString()) ?? 0;
        final courseId = int.tryParse(body['context_code'].toString().replaceFirst('course_', '')) ?? 0;
        final recipient = (_classmates[courseId] ?? const <(int, String)>[]).where((u) => u.$1 == recipientId);
        final course = _courses.where((c) => c['id'] == courseId);
        final created = _conversation(
          _nextId++,
          'sent',
          body['subject']?.toString() ?? 'No Subject',
          course.isEmpty ? '' : course.first['course_code'],
          recipientId,
          recipient.isEmpty ? 'Recipient' : recipient.first.$2,
          [_message(_selfId, 0, body['body']?.toString() ?? '')],
        );
        _conversations.insert(0, created);
        return _json([_conversationSummary(created)], 201);
      }

      final folder = request.url.queryParameters['scope'] ?? 'inbox';
      final listed = _conversations.where((c) => c['folder'] == folder).map(_conversationSummary).toList()
        ..sort((a, b) => (b['last_message_at'] as String).compareTo(a['last_message_at'] as String));
      return _json(listed);
    }

    final conversation = _findConversation(parts[1]);
    if (conversation == null) return null;

    if (parts.length == 3 && parts[2] == 'add_message' && method == 'POST') {
      (conversation['messages'] as List).insert(0, _message(_selfId, 0, request.bodyFields['body'] ?? ''));
      return _json(_conversationDetail(conversation), 201);
    }
    if (parts.length != 2) return null;

    if (method == 'DELETE') {
      _conversations.remove(conversation);
    } else if (method == 'PUT') {
      // Marking as read arrives form-encoded and archiving arrives as JSON, as in the real app.
      if (request.body.contains('archived')) {
        conversation['folder'] = 'archived';
      }
      conversation['workflow_state'] = 'read';
    }
    return _json(_conversationDetail(conversation));
  }

  // ---- The AI Assistant and Auto-Plan ----
  // The real assistant sits behind a proxy that needs a Canvas token, so the demo writes its
  // replies here from the mock data. It still asks for the app's tools first, which keeps the
  // "Checking your tasks" steps visible.

  static const String _demoNote = '\n\n*Demo mode: this is a sample reply written from mock data, not a live AI answer.*';

  static http.Response _chatReply({String? content, String? tool, Map<String, dynamic> args = const {}}) => _json({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': content,
              if (tool != null)
                'tool_calls': [
                  {
                    'id': 'call_demo_${DateTime.now().microsecondsSinceEpoch}',
                    'type': 'function',
                    'function': {'name': tool, 'arguments': jsonEncode(args)},
                  }
                ],
            },
          }
        ],
      });

  http.Response _chat(http.Request request) {
    final Map<String, dynamic> body = jsonDecode(request.body);
    final List<dynamic> messages = body['messages'] ?? [];
    if (messages.isEmpty) return _json({'error': 'messages is required'}, 400);

    if (body['tools'] == null) return _chatReply(content: _studyPlan(messages.last['content']?.toString() ?? ''));

    final last = messages.last as Map;
    if (last['role'] == 'tool') {
      return _chatReply(content: '${_answerFor(last['name']?.toString() ?? '', last['content']?.toString() ?? '')}$_demoNote');
    }

    final question = (last['content'] ?? '').toString().toLowerCase();
    bool mentions(String pattern) => RegExp(pattern).hasMatch(question);

    final named = _assignments.where((a) => question.contains(a['name'].toString().toLowerCase())).toList();
    if (named.isNotEmpty || mentions(r'instruction|what do i (need|have) to submit')) {
      final target = named.isNotEmpty ? named.first : _pending().first;
      return _chatReply(tool: 'get_assignment_details', args: {'assignment_name': target['name']});
    }
    if (mentions(r'grade|score|standing|passing|failing')) return _chatReply(tool: 'get_course_grades');
    if (mentions(r'announce|news|posted')) return _chatReply(tool: 'get_recent_announcements');
    if (mentions(r'message|inbox|mail|professor said|reply|replied')) {
      return _chatReply(tool: 'get_messages', args: {'folder': mentions(r'sent') ? 'sent' : 'inbox'});
    }
    if (mentions(r'task|due|deadline|assignment|to ?do|week|today|tomorrow|plan|priorit|overdue|missing|work|focus|first|next')) {
      return _chatReply(tool: 'get_pending_tasks');
    }

    return _chatReply(
      content: "I'm running in demo mode, so I answer from the sample data in this showcase. Try one of these:\n\n"
          '- **What is due this week?**\n'
          '- **How are my grades?**\n'
          '- **Any new announcements?**\n'
          '- **Do I have unread messages?**\n'
          '- **What are the instructions for Usability Test Plan?**$_demoNote',
    );
  }

  List<Map<String, dynamic>> _pending() {
    final pending = _assignments.where((a) {
      final submission = a['submission'] as Map;
      return submission['submitted_at'] == null && a['locked_for_user'] != true;
    }).toList()
      ..sort((a, b) => (a['due_at'] as String).compareTo(b['due_at'] as String));
    return pending;
  }

  String _courseCode(Object? courseId) =>
      _courses.firstWhere((c) => c['id'] == courseId)['course_code'] as String;

  String _answerFor(String tool, String toolResult) {
    switch (tool) {
      case 'get_pending_tasks':
        return _tasksAnswer();
      case 'get_course_grades':
        final rows = _courses.map((c) => '| ${c['course_code']} | ${_courseScores[c['id']]}% |').join('\n');
        final lowest = _courses.reduce((a, b) => _courseScores[a['id']]! <= _courseScores[b['id']]! ? a : b);
        return "Here are your current grades:\n\n| Course | Grade |\n| --- | --- |\n$rows\n\n"
            "You're passing every course. **${lowest['course_code']}** is your lowest, so that is where extra effort pays off most.";
      case 'get_recent_announcements':
        final lines = <String>[];
        for (final course in _courses) {
          for (final a in _announcements[course['id']] ?? const <Map<String, dynamic>>[]) {
            final flag = a['read_state'] == 'unread' ? ' (new)' : '';
            lines.add('- **${course['course_code']}** [${a['title']}](velo://announcements?courseId=${course['id']})$flag');
          }
        }
        return 'Recent announcements across your courses:\n\n${lines.join('\n')}';
      case 'get_messages':
        final sent = toolResult.contains('in sent');
        final threads = _conversations.where((c) => c['folder'] == (sent ? 'sent' : 'inbox')).toList();
        if (threads.isEmpty) return 'That folder is empty.';
        final lines = threads.map((c) {
          final who = (c['participants'] as List).first['name'];
          final flag = c['workflow_state'] == 'unread' ? ' (unread)' : '';
          return '- **$who**: [${c['subject']}](velo://conversation?threadId=${c['id']})$flag';
        });
        final unread = threads.where((c) => c['workflow_state'] == 'unread').length;
        final lead = sent ? 'Messages you sent:' : 'You have **$unread unread** ${unread == 1 ? 'message' : 'messages'}:';
        return '$lead\n\n${lines.join('\n')}';
      case 'get_assignment_details':
        final match = RegExp(r'^Instructions for (.*?): (.*)$', dotAll: true).firstMatch(toolResult);
        if (match == null) return "I couldn't find that assignment in your courses.";
        final assignment = _assignments.firstWhere((a) => a['name'] == match.group(1), orElse: () => {});
        final link = assignment.isEmpty
            ? '**${match.group(1)}**'
            : '[${match.group(1)}](velo://task?courseId=${assignment['course_id']}&taskId=${assignment['id']})';
        return 'Here is what $link asks for:\n\n${match.group(2)}';
      default:
        return toolResult;
    }
  }

  String _tasksAnswer() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final groups = <String, List<String>>{'Overdue': [], 'Due today': [], 'This week': [], 'Later': []};

    for (final a in _pending()) {
      final due = DateTime.parse(a['due_at'] as String).toLocal();
      final days = DateTime(due.year, due.month, due.day).difference(today).inDays;
      final group = days < 0 ? 'Overdue' : days == 0 ? 'Due today' : days <= 7 ? 'This week' : 'Later';
      groups[group]!.add(
        '- [${a['name']}](velo://task?courseId=${a['course_id']}&taskId=${a['id']}) · '
        '${_courseCode(a['course_id'])} · ${DateFormat('EEE, MMM d').format(due)}',
      );
    }

    final sections = groups.entries.where((g) => g.value.isNotEmpty).map((g) => '**${g.key}**\n${g.value.join('\n')}');
    return "Here is what's on your plate:\n\n${sections.join('\n\n')}\n\n"
        'Start with anything overdue, then the task due today.';
  }

  // Auto-Plan expects a JSON array of milestones and nothing else.
  String _studyPlan(String prompt) {
    final days = int.tryParse(RegExp(r'Total time until due: (\d+) days').firstMatch(prompt)?.group(1) ?? '') ?? 3;
    final title = RegExp(r'Task: (.*?)\. Course:').firstMatch(prompt)?.group(1) ?? 'the assignment';

    final steps = [
      ('Read the brief for $title and list what to submit', 0.0, 30),
      ('Outline your approach and gather materials', 0.3, 45),
      ('Do the main work on $title', 0.6, 90),
      ('Review against the rubric and submit', 1.0, 30),
    ];
    return jsonEncode([
      for (final (stepTitle, fraction, minutes) in steps)
        {'title': stepTitle, 'dateOffset': (days * fraction).round(), 'minutes': minutes},
    ]);
  }
}
