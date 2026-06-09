import 'package:flutter_test/flutter_test.dart';

import 'package:istatis_app/main.dart';

void main() {
  testWidgets('App shows auth gate when Supabase is not configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const IstatisApp());
    await tester.pump();

    expect(
      find.textContaining('Supabase is not configured'),
      findsOneWidget,
    );
  });
}
