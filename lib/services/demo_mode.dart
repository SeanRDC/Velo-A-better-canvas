// Demo mode: a showcase version of Velo for people without a HAU Canvas account. It is opened
// with the /demo link, skips sign-in, and answers every request from mock data in the app.
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_backend.dart';

class DemoMode {
  static bool enabled = false;

  // Answers Canvas and AI requests while the demo is on. Null in the real app.
  static http.Client? client;

  static const String _token = 'demo';
  static const String _storagePrefix = 'velo_demo.';

  // True for .../demo and ...?demo on the web build, or when built with --dart-define=VELO_DEMO=true.
  static bool requestedBy(Uri uri) {
    if (const bool.fromEnvironment('VELO_DEMO')) return true;
    if (!kIsWeb) return false;
    return uri.pathSegments.contains('demo') || uri.queryParameters.containsKey('demo');
  }

  // Must run before SharedPreferences is first read: the demo keeps its saved data under its
  // own prefix, so it never touches the token or cache of a real signed-in session.
  static void enable() {
    enabled = true;
    client = buildDemoClient();
    SharedPreferences.setPrefix(_storagePrefix);
  }

  // Starts a demo session. The mock data resets on every page load, so data cached from an
  // earlier visit is dropped first.
  static Future<void> startSession(SharedPreferences prefs) async {
    final stale = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in stale) {
      await prefs.remove(key);
    }
    await prefs.setBool('isOffline', false);
    await signIn(prefs);
  }

  static Future<void> signIn(SharedPreferences prefs) => prefs.setString('canvas_api_token', _token);
}
