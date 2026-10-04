// Tests for instant loading from saved data and for which lists are paginated
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_project/services/canvas_service.dart';

const _base = 'https://hau.instructure.com';

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'CANVAS_BASE_URL=$_base', isOptional: true);
  });

  test('saved data is returned at once, then refreshed in the background', () async {
    SharedPreferences.setMockInitialValues({
      'canvas_api_token': 'token',
      'cache_announcements_901': '[{"id":1,"title":"Old"}]',
    });
    int requests = 0;
    final client = MockClient((request) async {
      requests++;
      await Future.delayed(const Duration(milliseconds: 50));
      return http.Response('[{"id":1,"title":"Old"},{"id":2,"title":"New"}]', 200);
    });

    await http.runWithClient(() async {
      final service = CanvasService();
      final revisionBefore = CanvasService.dataRevision.value;

      // Comes back before the network call has finished
      final first = await service.fetchAnnouncementsForCourse('901');
      expect(first.map((a) => a['title']), ['Old']);

      // Background refresh lands, saves the new data and notifies screens
      await Future.delayed(const Duration(milliseconds: 500));
      expect(CanvasService.dataRevision.value, revisionBefore + 1);

      final second = await service.fetchAnnouncementsForCourse('901');
      expect(second.map((a) => a['title']), ['Old', 'New']);

      // The reload right after a refresh does not hit Canvas again
      await Future.delayed(const Duration(milliseconds: 100));
      expect(requests, 1);
    }, () => client);
  });

  test('unchanged data does not notify screens', () async {
    SharedPreferences.setMockInitialValues({
      'canvas_api_token': 'token',
      'cache_announcements_902': '[{"id":1}]',
    });
    final client = MockClient((request) async => http.Response('[{"id":1}]', 200));

    await http.runWithClient(() async {
      final revisionBefore = CanvasService.dataRevision.value;
      await CanvasService().fetchAnnouncementsForCourse('902');
      await Future.delayed(const Duration(milliseconds: 500));
      expect(CanvasService.dataRevision.value, revisionBefore);
    }, () => client);
  });

  test('with nothing saved, the first load waits for Canvas', () async {
    SharedPreferences.setMockInitialValues({'canvas_api_token': 'token'});
    final client = MockClient((request) async => http.Response('[{"id":5,"title":"Fresh"}]', 200));

    await http.runWithClient(() async {
      final result = await CanvasService().fetchAnnouncementsForCourse('903');
      expect(result.single['title'], 'Fresh');
    }, () => client);
  });

  test('pull-to-refresh waits for Canvas even when data is saved', () async {
    SharedPreferences.setMockInitialValues({
      'canvas_api_token': 'token',
      'cache_announcements_904': '[{"id":1,"title":"Old"}]',
    });
    final client = MockClient((request) async => http.Response('[{"id":1,"title":"Updated"}]', 200));

    await http.runWithClient(() async {
      CanvasService.requestFresh();
      final result = await CanvasService().fetchAnnouncementsForCourse('904');
      expect(result.single['title'], 'Updated');
    }, () => client);
  });

  test('only assignments follow extra pages', () async {
    SharedPreferences.setMockInitialValues({'canvas_api_token': 'token'});
    final seen = <String>[];
    final client = MockClient((request) async {
      seen.add(request.url.toString());
      final isSecondPage = request.url.queryParameters['page'] == '2';
      if (isSecondPage) return http.Response('[{"id":2,"name":"B"}]', 200);

      final next = request.url.replace(queryParameters: {...request.url.queryParametersAll, 'page': '2'});
      return http.Response('[{"id":1,"name":"A"}]', 200, headers: {'link': '<$next>; rel="next"'});
    });

    await http.runWithClient(() async {
      final service = CanvasService();

      final assignments = await service.fetchRawAssignmentPayloads('905');
      expect(assignments.map((a) => a['name']), ['A', 'B']);
      expect(seen.length, 2);

      seen.clear();
      final conversations = await service.fetchConversations();
      expect(conversations.length, 1);
      expect(seen.length, 1);
    }, () => client);
  });

  test('a next link on another host is never followed with the token', () async {
    SharedPreferences.setMockInitialValues({'canvas_api_token': 'token'});
    final seen = <String>[];
    final client = MockClient((request) async {
      seen.add(request.url.host);
      return http.Response('[{"id":1,"name":"A"}]', 200,
          headers: {'link': '<https://evil.example/api/v1/steal?page=2>; rel="next"'});
    });

    await http.runWithClient(() async {
      final assignments = await CanvasService().fetchRawAssignmentPayloads('906');
      expect(assignments.length, 1);
      expect(seen, ['hau.instructure.com']);
    }, () => client);
  });
}
