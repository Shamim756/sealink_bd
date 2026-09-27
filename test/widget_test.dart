import 'package:flutter_test/flutter_test.dart';
import 'package:sealink_bd/app.dart';
import 'package:sealink_bd/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const SeaLinkApp(),
      ),
    );

    // Splash screen-এ "SeaLink BD" text আছে কিনা check
    expect(find.text('SeaLink BD'), findsOneWidget);
  });
}