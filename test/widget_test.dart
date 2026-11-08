import 'package:flutter_test/flutter_test.dart';

import 'package:student_directory/main.dart';

void main() {
  testWidgets('Student Directory opens successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Student Directory'), findsOneWidget);
  });
}
