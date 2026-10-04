// Tests for the side panel's profile header
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_project/components/side_drawer.dart';
import 'package:final_project/state/app_state.dart';

void main() {
  testWidgets('tapping the profile header opens Account & Settings', (tester) async {
    dotenv.loadFromString(envString: 'CANVAS_BASE_URL=', isOptional: true);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(
            body: Row(children: [SizedBox(width: 300, child: SideDrawer(activeTab: 'tasks', isDesktop: true))]),
          ),
        ),
        GoRoute(path: '/account', builder: (context, state) => const Scaffold(body: Text('ACCOUNT PAGE'))),
      ],
    );

    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT PAGE'), findsNothing);

    // The header is the first avatar in the panel
    await tester.tap(find.byType(CircleAvatar).first);
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT PAGE'), findsOneWidget);
  });
}
