import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eco_track/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Smoke: app arranca y muestra UI principal', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Ajusta a algún widget estable de tu Home o barra inferior
    expect(find.byType(app.EcoTrackApp), findsOneWidget);
  });
}
