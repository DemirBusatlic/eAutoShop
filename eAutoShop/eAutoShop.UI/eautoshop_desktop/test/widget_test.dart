import 'package:eautoshop_desktop/app.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Prikazuje login ekran', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MyApp(),
      ),
    );

    expect(find.text('Prijava u desktop aplikaciju'), findsOneWidget);
  });
}
