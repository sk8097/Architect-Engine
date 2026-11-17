import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:architect_engine/main.dart';
import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Architect Engine home screen boots', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const ArchitectEngineApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ARCHITECT ENGINE'), findsOneWidget);
  });
}
