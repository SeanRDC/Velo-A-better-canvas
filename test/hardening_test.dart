// Tests for submission status, safe link handling, error text and logout cleanup
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_project/models/task.dart';
import 'package:final_project/services/canvas_service.dart';
import 'package:final_project/services/error_text.dart';
import 'package:final_project/services/planner_store.dart';
import 'package:final_project/services/safe_launch.dart';

void main() {
  group('Task.submittedFromJson', () {
    test('uses the student\'s own submission, not the class-wide flag', () {
      // Someone else submitted, this student has not
      expect(
        Task.submittedFromJson({
          'has_submitted_submissions': true,
          'submission': {'workflow_state': 'unsubmitted', 'submitted_at': null},
        }),
        isFalse,
      );
    });

    test('counts submitted, graded and pending review work as done', () {
      expect(Task.submittedFromJson({'submission': {'workflow_state': 'submitted', 'submitted_at': '2026-10-01T00:00:00Z'}}), isTrue);
      expect(Task.submittedFromJson({'submission': {'workflow_state': 'graded', 'submitted_at': null}}), isTrue);
      expect(Task.submittedFromJson({'submission': {'workflow_state': 'pending_review'}}), isTrue);
    });

    test('keeps missing work pending even when auto-graded', () {
      expect(Task.submittedFromJson({'submission': {'workflow_state': 'graded', 'missing': true}}), isFalse);
    });

    test('falls back to the old flag when no submission is included', () {
      expect(Task.submittedFromJson({'has_submitted_submissions': true}), isTrue);
      expect(Task.submittedFromJson({}), isFalse);
    });
  });

  group('resolveSafeUrl', () {
    test('allows web and mail links', () {
      expect(resolveSafeUrl('https://example.com/a')?.host, 'example.com');
      expect(resolveSafeUrl(' http://example.com ')?.scheme, 'http');
      expect(resolveSafeUrl('mailto:prof@hau.edu.ph')?.scheme, 'mailto');
    });

    test('resolves Canvas site-relative links to Canvas', () {
      expect(resolveSafeUrl('/courses/1/files/2').toString(), 'https://hau.instructure.com/courses/1/files/2');
    });

    test('rejects other schemes and empty input', () {
      expect(resolveSafeUrl('javascript:alert(1)'), isNull);
      expect(resolveSafeUrl('file:///etc/passwd'), isNull);
      expect(resolveSafeUrl('intent://scan/#Intent;end'), isNull);
      expect(resolveSafeUrl('tel:123'), isNull);
      expect(resolveSafeUrl('//evil.example/x'), isNull);
      expect(resolveSafeUrl(''), isNull);
    });
  });

  group('friendlyError', () {
    test('shows the app\'s own exception message', () {
      expect(friendlyError(Exception('Cannot delete messages while offline.'), 'fallback'), 'Cannot delete messages while offline.');
    });

    test('hides anything else behind the fallback', () {
      expect(friendlyError(const FormatException('Unexpected character at 12'), 'fallback'), 'fallback');
      expect(friendlyError(StateError('bad state'), 'fallback'), 'fallback');
    });
  });

  test('clearSession removes account data and keeps app preferences', () async {
    dotenv.loadFromString(envString: 'CANVAS_BASE_URL=', isOptional: true);
    SharedPreferences.setMockInitialValues({
      'canvas_api_token': 'secret',
      'cache_user_profile': '{}',
      'cache_assignments_42': '[]',
      'cache_conv_7': '{}',
      'last_sync_time': '2026-10-04T00:00:00.000',
      PlannerStore.storageKey: '{}',
      'theme': 'dark',
      'isOffline': false,
    });

    await CanvasService().clearSession();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), unorderedEquals(['theme', 'isOffline']));
  });
}
