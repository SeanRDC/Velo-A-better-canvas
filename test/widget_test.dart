// Initial Widget Test for VeloApp
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:final_project/main.dart';
import 'package:final_project/state/app_state.dart';

void main() {
  testWidgets('App loads and displays the Login Screen', (tester) async {
    // Inject mock SharedPreferences for the testing environment
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build the app using the new VeloApp class wrapped in its Provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(prefs),
        child: const VeloApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('A Better Canvas'), findsOneWidget);
    expect(find.text('Log in with Canvas'), findsOneWidget);
  });
}