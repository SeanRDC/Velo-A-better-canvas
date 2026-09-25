// Main Application Entry Point and Router
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/courses_screen.dart';
import 'models/course.dart';
import 'screens/course_detail_screen.dart';
import 'screens/course_grades_screen.dart';
import 'screens/course_modules_screen.dart';
import 'screens/course_assignments_screen.dart';
import 'screens/task_detail_screen.dart';
import 'models/task.dart';
import 'screens/course_announcements_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: DevicePreview(
        enabled: true,
        builder: (context) => const VeloApp(),
      ),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/assistant',
      builder: (context, state) => const AiAssistantScreen(),
    ),
    GoRoute(
      path: '/courses',
      builder: (context, state) => const CoursesScreen(),
    ),
    GoRoute(
      path: '/course', // Using 'extra' to pass the object directly
      builder: (context, state) {
        // Retrieve the Course object passed from the InkWell
        final course = state.extra as Course;
        return CourseDetailScreen(course: course);
      },
    ),
    GoRoute(
      path: '/course-grades',
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseGradesScreen(course: course);
      },
    ),
    GoRoute(
      path: '/course-modules',
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseModulesScreen(course: course);
      },
    ),
    GoRoute(
      path: '/course-assignments',
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseAssignmentsScreen(course: course);
      },
    ),
    GoRoute(
      path: '/task',
      builder: (context, state) {
        final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;
        final course = extras['course'] as Course;
        final task = extras['task'] as Task;
        return TaskDetailScreen(course: course, task: task);
      },
    ),
    GoRoute(
      path: '/course-announcements',
      builder: (context, state) {
        final course = state.extra as Course;
        return CourseAnnouncementsScreen(course: course);
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
      builder: DevicePreview.appBuilder,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.themeMode,
      routerConfig: _router,
    );
  }
}