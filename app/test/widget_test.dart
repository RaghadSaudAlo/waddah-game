import 'package:flutter_test/flutter_test.dart';

import 'package:waddah_app/core/app_scope.dart';
import 'package:waddah_app/core/session.dart';
import 'package:waddah_app/main.dart';

void main() {
  testWidgets('WaddahApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        notifier: AppSession(),
        child: const WaddahApp(),
      ),
    );
    expect(find.byType(WaddahApp), findsOneWidget);
  });
}
