// Tests for the bottom navigation order and fit on a small phone
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/components/bottom_nav.dart';

void main() {
  testWidgets('Campus++ sits between Courses and AI Assistant and fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(bottomNavigationBar: BottomNav(activeTab: 'tasks')),
    ));

    expect(tester.takeException(), isNull);

    double x(String label) => tester.getCenter(find.text(label)).dx;
    expect(x('Courses'), lessThan(x('Campus++')));
    expect(x('Campus++'), lessThan(x('AI Assistant')));
    expect(x('AI Assistant'), lessThan(x('Dashboard')));

    // Every label is fully on screen, on one line
    for (final label in ['Courses', 'Campus++', 'AI Assistant', 'Dashboard']) {
      final box = tester.getRect(find.text(label));
      expect(box.left, greaterThanOrEqualTo(0));
      expect(box.right, lessThanOrEqualTo(320));
      expect(box.height, lessThan(20));
    }
  });
}
