import 'package:flutter_test/flutter_test.dart';
import 'package:spare_kart/app.dart';

void main() {
  testWidgets('SpareKart app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SpareKartApp());
    await tester.pump();
    expect(find.text('SpareKart'), findsNothing);
  });
}
