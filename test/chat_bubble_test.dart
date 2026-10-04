// Tests for AI reply layout on small screens and the typing status bubble
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/components/chat_bubble.dart';
import 'package:final_project/screens/ai_assistant_screen.dart';

const _wideTable = '''
Here are your grades:

| Course | Current grade | Letter | Missing work | Last updated |
| --- | --- | --- | --- | --- |
| Data Communications and Networking | 92.45% | A- | 2 assignments | October 3, 2026 |
| Application Development and Emerging Technologies | 88.10% | B+ | None | October 1, 2026 |
''';

Future<void> _pumpAtWidth(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a wide table scrolls sideways on a phone instead of being squeezed', (tester) async {
    await _pumpAtWidth(tester, 320, const ChatBubble(text: _wideTable, isUser: false));

    // No layout overflow was reported
    expect(tester.takeException(), isNull);

    final table = tester.getSize(find.byType(Table));
    final bubble = tester.getSize(find.byType(ChatBubble));
    expect(table.width, greaterThan(bubble.width), reason: 'table keeps its natural width');

    // Cells stay on one line rather than wrapping letter by letter
    final cell = tester.getSize(find.text('Data Communications and Networking', findRichText: true).first);
    expect(cell.height, lessThan(30));

    // And the far column can be reached by dragging the visible part
    final tableBox = tester.getRect(find.byType(Table));
    await tester.dragFrom(Offset(220, tableBox.center.dy), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(Table)).dx, lessThan(tableBox.left));
  });

  testWidgets('bubbles stop growing on wide screens', (tester) async {
    final longText = List.filled(60, 'A long reply that keeps going.').join(' ');
    await _pumpAtWidth(tester, 1600, ChatBubble(text: longText, isUser: false));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(SelectionArea)).width, lessThanOrEqualTo(720));
    expect(tester.getSize(find.byType(SelectionArea)).width, greaterThan(600));
  });

  testWidgets('copy button copies the reply and confirms', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await _pumpAtWidth(tester, 360, const ChatBubble(text: 'Your next deadline is Friday.', isUser: false));

    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(copied, 'Your next deadline is Friday.');
    expect(find.text('Copied'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('user messages have no copy button', (tester) async {
    await _pumpAtWidth(tester, 360, const ChatBubble(text: 'Show my grades', isUser: true));
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('typing bubble shows what the assistant is doing and fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(280, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TypingBubble(status: 'Reading the assignment details', icon: Icons.description_outlined),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Reading the assignment details'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);

    // Status changes swap the text in place
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TypingBubble(status: 'Putting it together')),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Putting it together'), findsOneWidget);
    expect(find.text('Reading the assignment details'), findsNothing);
  });
}
