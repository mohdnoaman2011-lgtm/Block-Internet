import 'package:flutter_test/flutter_test.dart';
import 'package:block_internet/main.dart';

void main() {
  testWidgets('app starts and opens the main screen', (tester) async {
    await tester.pumpWidget(const BlockerApp());
    expect(find.text('Block Internet\nAccess'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Apps'), findsWidgets);
  });
}