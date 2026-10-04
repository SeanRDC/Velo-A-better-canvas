// Initial Widget Test for VeloApp
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:final_project/main.dart';
import 'package:final_project/state/app_state.dart';

void main() {
  testWidgets('App loads and displays the Login Screen', (tester) async {
    // Inject mock SharedPreferences for the testing environment
    dotenv.loadFromString(envString: 'CANVAS_BASE_URL=', isOptional: true);
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

    expect(find.text('Velo'), findsOneWidget);
    expect(find.text('Connect to Canvas'), findsOneWidget);

    // The token field comes first, then the connect button, then the help link
    final fieldY = tester.getTopLeft(find.byType(TextField)).dy;
    final buttonY = tester.getTopLeft(find.text('Connect to Canvas')).dy;
    final helpY = tester.getTopLeft(find.text('How do I find my access token?')).dy;
    expect(fieldY, lessThan(buttonY));
    expect(buttonY, lessThan(helpY));
  });
}