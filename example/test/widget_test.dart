import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_walkie_talkie_example/main.dart';

void main() {
  testWidgets('Walkie Talkie smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WalkieTalkieApp());
    expect(find.text('Local Walkie Talkie'), findsOneWidget);
  });
}
