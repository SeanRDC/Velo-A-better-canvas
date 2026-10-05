// App entry point: loads saved settings and the environment, defines the go_router routes,
// and starts the Velo app with its theme and global state.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'state/app_state.dart';
import 'components/reconnect_prompt.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/courses_screen.dart';
import 'models/course.dart';
import 'models/task.dart';
import 'screens/course_detail_screen.dart';
import 'screens/course_grades_screen.dart';
import 'screens/course_modules_screen.dart';
import 'screens/course_assignments_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/course_announcements_screen.dart';
import 'screens/module_item_detail_screen.dart';
import 'screens/account_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/conversation_detail_screen.dart';
import 'screens/compose_message_screen.dart';
import 'screens/planner_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  tz.initializeTimeZones();
  final prefs = await SharedPreferences.getInstance();

  if ((prefs.getString('canvas_api_token') ?? '').isNotEmpty) {
    _initialLocation = '/dashboard';
  }

  const String mobileFrameSetting = "disable";
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: DevicePreview(
        enabled: mobileFrameSetting == "enable",
        builder: (context) => const VeloApp(),
      ),
    ),
  );
}

String _initialLocation = '/';

// Turns the objects passed as route `extra` into a JSON string and back, so the browser can
// store them in its history. Without this, pressing back/forward on web drops the extra and
// the restored page has nothing to show.
class _ExtraCodec extends Codec<Object?, Object?> {
  const _ExtraCodec();

  @override
  Converter<Object?, Object?> get encoder => const _ExtraEncoder();

  @override
  Converter<Object?, Object?> get decoder => const _ExtraDecoder();
}

class _ExtraEncoder extends Converter<Object?, Object?> {
  const _ExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    try {
      return jsonEncode(input, toEncodable: _toEncodable);
    } catch (_) {
      return null;
    }
  }

  static Object? _toEncodable(Object? value) {
    if (value is Course) {
      return {
        '__type': 'Course',
        'id': value.id,
        'name': value.name,
        'courseCode': value.courseCode,
        'instructor': value.instructor,
        'term': value.term,
      };
    }
    if (value is Task) {
      return {
        '__type': 'Task',
        'id': value.id,
        'title': value.title,
        'courseId': value.courseId,
        'courseName': value.courseName,
        'courseCode': value.courseCode,
        'dueDate': value.dueDate.toIso8601String(),
        'points': value.points,
        'type': value.type,
        'isSubmitted': value.isSubmitted,
        'description': value.description,
        'isLocked': value.isLocked,
        'submissionTypes': value.submissionTypes,
      };
    }
    if (value is ModuleItem) {
      return {
        '__type': 'ModuleItem',
        'label': value.label,
        'kind': value.kind,
        'htmlUrl': value.htmlUrl,
        'apiUrl': value.apiUrl,
        'pageUrl': value.pageUrl,
        'indent': value.indent,
      };
    }
    if (value is DateTime) return value.toIso8601String();
    throw JsonUnsupportedObjectError(value);
  }
}

class _ExtraDecoder extends Converter<Object?, Object?> {
  const _ExtraDecoder();

  @override
  Object? convert(Object? input) {
    if (input is! String) return null;
    try {
      return jsonDecode(input, reviver: _revive);
    } catch (_) {
      return null;
    }
  }

  static Object? _revive(Object? key, Object? value) {
    if (value is! Map) return value;
    switch (value['__type']) {
      case 'Course':
        return Course(
          id: value['id'] as String,
          name: value['name'] as String,
          courseCode: value['courseCode'] as String,
          instructor: value['instructor'] as String,
          term: value['term'] as String,
        );
      case 'Task':
        return Task(
          id: value['id'] as String,
          title: value['title'] as String,
          courseId: value['courseId'] as String,
          courseName: value['courseName'] as String,
          courseCode: value['courseCode'] as String,
          dueDate: DateTime.parse(value['dueDate'] as String),
          points: value['points'] as int,
          type: value['type'] as String,
          isSubmitted: value['isSubmitted'] as bool,
          description: value['description'] as String,
          isLocked: value['isLocked'] as bool,
          submissionTypes: value['submissionTypes'] as List<dynamic>,
        );
      case 'ModuleItem':
        return ModuleItem(
          value['label'] as String,
          value['kind'] as String,
          value['htmlUrl'] as String,
          value['apiUrl'] as String?,
          value['pageUrl'] as String?,
          value['indent'] as int,
        );
    }
    return value;
  }
}

// Sends a detail route back to a safe screen when its extra is missing or the wrong type
// (for example a history entry saved before the data could be stored), instead of crashing.
GoRouterRedirect _requireExtra<T>(String fallback) =>
    (context, state) => state.extra is T ? null : fallback;

final _router = GoRouter(
  initialLocation: _initialLocation,
  extraCodec: const _ExtraCodec(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => navigationShell,
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/assistant',
              builder: (context, state) => const AiAssistantScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/courses',
              builder: (context, state) => const CoursesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/planner',
              builder: (context, state) {
                final taskId = state.extra as String?;
                return PlannerScreen(initialTaskId: taskId);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (context, state) => const InboxScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const AccountScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/course',
      redirect: _requireExtra<Course>('/courses'),
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseDetailScreen(course: course);
      },
    ),
    GoRoute(
      path: '/course-grades',
      redirect: _requireExtra<Course>('/courses'),
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseGradesScreen(course: course);
      },
    ),
    GoRoute(
      path: '/course-modules',
      redirect: _requireExtra<Course>('/courses'),
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseModulesScreen(course: course);
      },
    ),
    GoRoute(
      path: '/course-assignments',
      redirect: _requireExtra<Course>('/courses'),
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseAssignmentsScreen(course: course);
      },
    ),
    GoRoute(
      path: '/task',
      redirect: _requireExtra<Map<String, dynamic>>('/dashboard'),
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        final incomingData = extras['assignment'];
        
        Map<String, dynamic> safeMap;
        
        if (incomingData is Map<String, dynamic>) {
          safeMap = incomingData;
        } else {
          safeMap = {
            'name': incomingData.title,
            'due_at': incomingData.dueDate.toIso8601String(),
            'points_possible': incomingData.points,
            'has_submitted_submissions': incomingData.isSubmitted,
            'submission_types': incomingData.submissionTypes,
            'locked_for_user': incomingData.isLocked,
            'description': incomingData.description,
          };
        }
        
        return TaskDetailScreen(
          course: extras['course'] as Course,
          assignment: safeMap,
        );
      },
    ),
    GoRoute(
      path: '/course-announcements',
      redirect: _requireExtra<Course>('/courses'),
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseAnnouncementsScreen(course: course);
      },
    ),
    GoRoute(
      path: '/module-item',
      redirect: _requireExtra<Map<String, dynamic>>('/courses'),
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return ModuleItemDetailScreen(
          course: extras['course'] as Course,
          items: (extras['items'] as List).cast<ModuleItem>(),
          initialIndex: extras['index'] as int,
        );
      },
    ),
    GoRoute(
      path: '/compose',
      builder: (context, state) => const ComposeMessageScreen(),
    ),
    GoRoute(
      path: '/conversation',
      redirect: _requireExtra<Map<String, dynamic>>('/inbox'),
      builder: (context, state) {
        final thread = state.extra as Map<String, dynamic>;
        return ConversationDetailScreen(thread: thread);
      },
    ),
  ],
);

class VeloApp extends StatelessWidget {
  const VeloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp.router(
      title: 'Velo: Canvas Co-pilot',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: (context, child) => DevicePreview.appBuilder(
        context,
        ReconnectPrompt(
          navigatorKey: _router.routerDelegate.navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.themeMode,
      routerConfig: _router,
    );
  }
}