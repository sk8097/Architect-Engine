import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/providers/notification_provider.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/project_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('legacy projects and pre-taxonomy wizard briefs still load', () {
    final legacy = ProjectModel.fromMap({
      'name': 'Existing house', 'bhk': '2 BHK', 'floors': 'G+1', 'facing': 'East',
    });
    expect(legacy.brief, isNull);
    expect(legacy.description, '2 BHK • G+1 • East Facing');
    final oldBrief = ProjectBrief.fromMap({
      'type': 'villa', 'floorCount': 2, 'parking': 'none', 'features': ['Garden'],
    })!;
    expect(oldBrief.type, ProjectType.villa);
    expect(oldBrief.features, ['Garden']);
    expect(oldBrief.taxonomy, isNull);
  });

  test('registry has eight categories and valid scoped IDs/profile references', () {
    void unique(Iterable<String> ids) => expect(ids.toSet().length, ids.length);
    expect(projectTaxonomy.length, 8);
    unique(projectTaxonomy.map((c) => c.id));
    for (final category in projectTaxonomy) {
      expect(category.groups, isNotEmpty);
      unique(category.groups.map((g) => g.id));
      for (final group in category.groups) {
        expect(group.types, isNotEmpty);
        unique(group.types.map((t) => t.id));
        for (final type in group.types) {
          final profile = taxonomyProgram(group, type);
          expect(profile.configurations, isNotEmpty);
          expect(profile.spaces, isNotEmpty);
          unique(profile.configurations.map((o) => o.id));
          unique(profile.spaces.map((o) => o.id));
        }
      }
    }
  });

  Future<ProjectProvider> openWizard(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final projects = ProjectProvider();
    final notifications = NotificationProvider();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectProvider>.value(value: projects),
        ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () => ProjectWizardScreen.open(context),
              child: const Text('New Project'),
            );
          }),
        ),
      ),
    ));
    await tap(tester, 'New Project');
    expect(find.text('Category'), findsOneWidget);
    return projects;
  }

  Future<void> selectVilla(WidgetTester tester) async {
    await tap(tester, 'Residential');
    await tap(tester, 'House / low-rise dwelling');
    await tap(tester, 'Villa');
    await choose(tester, 'House configuration (optional)', '2 BHK');
    await tap(tester, 'Continue');
    await tap(tester, 'Garden');
  }

  testWidgets('villa path validates and saves versioned selection, quantity and dimensions', (tester) async {
    final projects = await openWizard(tester);
    await selectVilla(tester);
    final quantity = find.byType(TextFormField);
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '0');
    await tap(tester, 'Continue');
    expect(find.text('Enter a positive quantity.'), findsOneWidget);
    await tester.enterText(quantity, '2');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    expect(find.text('Enter a project name.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'North View');
    await tap(tester, 'Continue');
    await choose(tester, 'Plot geometry (optional)', 'Rectangular');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (ft)')), '40');
    await tap(tester, 'Continue');
    expect(find.text('Enter both dimensions or leave both blank.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('Plot depth (ft)')), '60');
    await tap(tester, 'Continue'); // Site to jurisdiction.
    await tap(tester, 'Continue'); // Jurisdiction to facility.
    await choose(tester, 'Parking (optional)', 'No parking');
    final bedrooms = find.descendant(of: find.byKey(const ValueKey('bedrooms')), matching: find.byType(TextFormField));
    await tester.ensureVisible(bedrooms);
    await tester.enterText(bedrooms, '3');
    await tap(tester, 'Continue');
    expect(find.textContaining('Bedroom count must match'), findsOneWidget);
    await tester.enterText(bedrooms, '2');
    await goToReview(tester);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('40 × 60 ft'), findsOneWidget);
    expect(find.text('Quantity: 2'), findsOneWidget);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.bhk, '2 BHK');
    final prefs = await SharedPreferences.getInstance();
    final stored = ProjectModel.fromJson(prefs.getStringList('ae_projects_v1')!.single);
    final selected = stored.brief!.taxonomy!;
    expect(selected.version, projectTaxonomyVersion);
    expect(selected.categoryId, 'residential');
    expect(selected.subcategoryId, 'houses');
    expect(selected.typeId, 'villa');
    expect(selected.configurationId, '2_bhk');
    expect(selected.spaceQuantities, {'garden': 2});
    expect(stored.brief!.floorCount, isNull);
    expect(stored.brief!.parking, ProjectParking.none);
    expect(stored.brief!.requirements!.answers['bedrooms'], 2);
  });

  testWidgets('back and a category change keep the site but reset dependent choices', (tester) async {
    final projects = await openWizard(tester);
    await selectVilla(tester);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Site A');
    await tap(tester, 'Continue');
    await choose(tester, 'Plot geometry (optional)', 'Irregular Polygon');
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    await tap(tester, 'Industrial & Warehousing');
    await tap(tester, 'Warehouse / logistics');
    await tap(tester, 'General Warehouse');
    expect(find.text('2 BHK'), findsNothing);
    await choose(tester, 'Storage layout (optional)', 'Rack Storage');
    await tap(tester, 'Continue');
    expect(find.text('Garden'), findsNothing);
    expect(find.text('Loading Bay'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Site A'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Irregular Polygon'), findsOneWidget);
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.brief!.taxonomy!.spaceQuantities, isEmpty);
    expect(saved.brief!.taxonomy!.typeId, 'general_warehouse');
    expect(saved.toMap()['width'], isNull);
    expect(saved.toMap()['length'], isNull);
  });

  testWidgets('road uses route inputs and does not require building plot fields', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Transport infrastructure');
    await tap(tester, 'Road');
    await tap(tester, 'Continue'); // Configuration.
    await tap(tester, 'Continue'); // Components.
    await tester.enterText(find.byType(TextFormField).first, 'New road');
    await tap(tester, 'Continue');
    expect(find.byKey(const ValueKey('Plot geometry (optional)')), findsNothing);
    final field = find.descendant(of: find.byKey(const ValueKey('route_length')), matching: find.byType(TextFormField));
    await tester.ensureVisible(field);
    await tester.enterText(field, '1200.5');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['route_length'], 1200.5);
    expect(projects.projects.single.brief!.taxonomy!.plotShapeId, isNull);
  });

}

Future<void> goToReview(WidgetTester tester) async {
  for (var i = 0; i < 8 && find.text('Review').evaluate().isEmpty; i++) {
    await tap(tester, 'Continue');
  }
  expect(find.text('Review'), findsOneWidget);
}

Future<void> choose(WidgetTester tester, String label, String option) async {
  final field = find.byKey(ValueKey(label));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tap(tester, option);
}

Future<void> tap(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
