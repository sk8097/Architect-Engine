import 'package:architect_engine/providers/app_state_provider.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/calculator_dialog.dart';
import 'package:architect_engine/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> openHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => ProjectProvider()),
    ],
    child: const MaterialApp(home: HomeScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home measurement shortcut opens the category and its calculator', (tester) async {
    await openHome(tester);
    final shortcut = find.text('Measurement');
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pumpAndSettle();

    final selectedCategory = find.byKey(const ValueKey('tools-category-measure'));
    expect(tester.widget<ChoiceChip>(selectedCategory).selected, isTrue);
    await tester.enterText(find.byType(TextField), 'Area Calculator');
    await tester.pumpAndSettle();
    expect(find.text('Length & Distance'), findsNothing);
    final result = find.descendant(
      of: find.byType(SliverGrid),
      matching: find.text('Area Calculator'),
    );
    expect(result, findsOneWidget);
    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(tester.widget<CalculatorDialog>(find.byType(CalculatorDialog)).tool.id, 2);
  });

  testWidgets('The app drawer opens Tools and a favorite can be filtered', (tester) async {
    await openHome(tester);
    await tester.tap(find.byTooltip('Open Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tools & Utilities'));
    await tester.pumpAndSettle();
    expect(find.text('168 Professional Tools'), findsOneWidget);

    final toolName = find.text('Length & Distance');
    final toolCard = find.ancestor(of: toolName, matching: find.byType(Card));
    await tester.tap(find.descendant(of: toolCard, matching: find.byTooltip('Add to favorites')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tools-category-fav')));
    await tester.pumpAndSettle();
    expect(toolName, findsOneWidget);
    expect(find.text('Area Calculator'), findsNothing);
  });
}
