import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_track/main.dart';

void main() {
  testWidgets('App shell renders home action', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HandTrackApp()));

    expect(find.text('Start today\'s session'), findsOneWidget);
  });
}
