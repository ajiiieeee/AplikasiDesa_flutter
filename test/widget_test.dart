import 'package:flutter_test/flutter_test.dart';
import 'package:digitalv/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(isLoggedIn: false));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
