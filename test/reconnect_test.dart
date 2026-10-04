// Tests for detecting a returning connection in offline mode and the prompt
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_project/components/reconnect_prompt.dart';
import 'package:final_project/state/app_state.dart';

const _interval = Duration(milliseconds: 30);

// Long enough for several connection checks to run
Future<void> _wait() => Future<void>.delayed(_interval * 5);

Future<AppState> _appState({required bool offline, required bool Function() connected, bool signedIn = true}) async {
  SharedPreferences.setMockInitialValues({
    'isOffline': offline,
    if (signedIn) 'canvas_api_token': 'token',
  });
  final prefs = await SharedPreferences.getInstance();
  return AppState(prefs, connectionProbe: () async => connected(), probeInterval: _interval);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('launching in offline mode with a connection asks to go online', () async {
    final state = await _appState(offline: true, connected: () => true);
    await _wait();

    expect(state.reconnectAvailable, isTrue);
    state.goOnline();
    expect(state.isOffline, isFalse);
    expect(state.reconnectAvailable, isFalse);
    state.dispose();
  });

  test('turning offline mode on while connected does not ask until the connection drops and returns', () async {
    bool connected = true;
    final state = await _appState(offline: false, connected: () => connected);

    state.toggleOffline();
    await _wait();
    expect(state.reconnectAvailable, isFalse, reason: 'the user chose offline while connected');

    connected = false;
    await _wait();
    expect(state.reconnectAvailable, isFalse);

    connected = true;
    await _wait();
    expect(state.reconnectAvailable, isTrue);
    state.dispose();
  });

  test('"Stay offline" stops asking until the connection drops again', () async {
    bool connected = true;
    final state = await _appState(offline: true, connected: () => connected);
    await _wait();
    expect(state.reconnectAvailable, isTrue);

    state.dismissReconnectPrompt();
    await _wait();
    expect(state.isOffline, isTrue);
    expect(state.reconnectAvailable, isFalse);

    connected = false;
    await _wait();
    connected = true;
    await _wait();
    expect(state.reconnectAvailable, isTrue);
    state.dispose();
  });

  test('no checks happen while signed out or in online mode', () async {
    int probes = 0;
    bool probe() {
      probes++;
      return true;
    }

    final signedOut = await _appState(offline: true, connected: probe, signedIn: false);
    await _wait();
    expect(probes, 0);
    expect(signedOut.reconnectAvailable, isFalse);
    signedOut.dispose();

    final online = await _appState(offline: false, connected: probe);
    await _wait();
    expect(probes, 0);
    expect(online.reconnectAvailable, isFalse);
    online.dispose();
  });

  Future<AppState> pumpWithPrompt(WidgetTester tester) async {
    final state = (await tester.runAsync(() => _appState(offline: true, connected: () => true)))!;
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => ReconnectPrompt(navigatorKey: navigatorKey, child: child!),
        home: const Scaffold(body: Text('Dashboard')),
      ),
    ));
    await tester.runAsync(_wait);
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('the prompt appears and "Go online" leaves offline mode', (tester) async {
    final state = await pumpWithPrompt(tester);
    expect(find.text('Connection detected'), findsOneWidget);

    await tester.tap(find.text('Go online'));
    await tester.pumpAndSettle();

    expect(find.text('Connection detected'), findsNothing);
    expect(state.isOffline, isFalse);
    state.dispose();
  });

  testWidgets('"Stay offline" closes the prompt and keeps offline mode', (tester) async {
    final state = await pumpWithPrompt(tester);
    expect(find.text('Connection detected'), findsOneWidget);

    await tester.tap(find.text('Stay offline'));
    await tester.pumpAndSettle();
    await tester.runAsync(_wait);
    await tester.pumpAndSettle();

    expect(find.text('Connection detected'), findsNothing);
    expect(state.isOffline, isTrue);
    expect(state.reconnectAvailable, isFalse);
    state.dispose();
  });
}
