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

  Future<void> enterField(WidgetTester tester, String id, String value) async {
    final field = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(TextFormField));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  Future<void> enterHomeSite(WidgetTester tester, {String width = '40', String depth = '60'}) async {
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (ft)')), width);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (ft)')), depth);
    await tester.pumpAndSettle();
    await choose(tester, 'Front-facing side (required)', 'South');
  }

  Future<void> enterHomeBasics(WidgetTester tester) async {
    final floors = find.byKey(const ValueKey('floor_count'));
    await tester.ensureVisible(floors);
    await tester.enterText(floors, '1');
    await tester.pumpAndSettle();
    await choose(tester, 'Parking (required)', 'No parking');
    final puja = find.byKey(const ValueKey('puja_needed'));
    await tester.ensureVisible(puja);
    await tester.tap(find.descendant(of: puja, matching: find.byType(DropdownButtonFormField<String>)));
    await tester.pumpAndSettle();
    await tap(tester, 'No');
  }

  Future<void> selectVilla(WidgetTester tester) async {
    await tap(tester, 'Residential');
    await tap(tester, 'House / low-rise dwelling');
    await tap(tester, 'Villa');
    await enterHomeSite(tester);
    await choose(tester, 'House configuration (optional)', '2 BHK');
    await enterHomeBasics(tester);
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
    expect(stored.brief!.floorCount, 1);
    expect(stored.brief!.parking, ProjectParking.none);
    expect(stored.brief!.requirements!.answers['puja_needed'], 'no');
  });

  testWidgets('back and a category change keep the site but reset dependent choices', (tester) async {
    final projects = await openWizard(tester);
    await selectVilla(tester);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Site A');
    await tap(tester, 'Continue');
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    await tap(tester, 'Industrial & Warehousing');
    await tap(tester, 'Warehouse / logistics');
    await tap(tester, 'General Warehouse');
    expect(find.text('2 BHK'), findsNothing);
    expect(find.text('Rectangular'), findsOneWidget);
    await choose(tester, 'Plot geometry (required)', 'Irregular Polygon');
    await enterField(tester, 'surveyed_plot_area', '250');
    await choose(tester, 'Storage layout (optional)', 'Rack Storage');
    await enterField(tester, 'clear_height', '6');
    await enterField(tester, 'commodity', 'Packed cartons');
    await tap(tester, 'Continue');
    expect(find.text('Garden'), findsNothing);
    expect(find.text('Loading Bay'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Site A'), findsOneWidget);
    await tap(tester, 'Continue');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.brief!.taxonomy!.spaceQuantities, isEmpty);
    expect(saved.brief!.taxonomy!.typeId, 'general_warehouse');
    expect(saved.toMap()['width'], isNull);
    expect(saved.toMap()['length'], isNull);
  });

  testWidgets('bicycle rack mode at a metro station does not require a traffic survey', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Transport infrastructure');
    await tap(tester, 'Metro Station');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '12');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '16');
    await tester.pumpAndSettle();
    Future<void> pick(String id, String label) async {
      final dropdown = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(DropdownButtonFormField<String>));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tap(tester, label);
    }
    await pick('cad_output', 'Bicycle parking: measured two-sided stands');
    await pick('br_banks', 'Two mirrored rows');
    for (final entry in const {
      'br_stands': '5', 'br_cycle_l': '1.9', 'br_cycle_w': '0.65', 'br_stand_l': '0.8', 'br_stand_w': '0.1',
      'br_flank': '0.075', 'br_pitch': '1.8', 'br_pair_gap': '0.25', 'br_aisle': '2.2', 'br_outer': '0.5',
      'br_head_s': '1.5', 'br_head_n': '1.2', 'br_west': '2', 'br_south': '2', 'br_target': '20',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Project information'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Cycle parking');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['br_target'], 20);
    expect(find.text('Bicycle rack CAD'), findsOneWidget);
    expect(find.text('Share bicycle rack DXF'), findsOneWidget);
  });

  testWidgets('memorial niche mode saves measured geometry without a generic landscape note', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Cemetery/Memorial Landscape');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '20');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '10');
    await tester.pumpAndSettle();
    await choose(tester, 'Public realm arrangement (optional)', 'Public Open Space');
    Future<void> pick(String id, String label) async {
      final dropdown = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(DropdownButtonFormField<String>));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tap(tester, label);
    }
    await pick('cad_output', 'Memorial: measured niche walls and elevation');
    await pick('mn_faces', 'South and north faces');
    for (final entry in const {
      'mn_panels': '3', 'mn_columns': '8', 'mn_tiers': '4', 'mn_width': '0.36', 'mn_height': '0.32',
      'mn_depth': '0.4', 'mn_web': '0.06', 'mn_frame': '0.12', 'mn_core': '0.16', 'mn_plinth': '0.3',
      'mn_gap': '0.5', 'mn_ends': '1.2', 'mn_south_strip': '1.8', 'mn_north_strip': '1.5',
      'mn_west': '2', 'mn_south': '3', 'mn_target': '192',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Project information'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Memorial');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['mn_target'], 192);
    expect(find.text('Memorial niche wall CAD'), findsOneWidget);
    expect(find.text('Share niche plan DXF'), findsOneWidget);
  });

  testWidgets('outdoor tennis opt-in saves measured inputs and opens the DXF preview', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Institutional & Public Utility');
    await tap(tester, 'Sports / recreation / public amenities');
    await tap(tester, 'Sports Complex');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '42');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '44');
    await tester.pumpAndSettle();
    await choose(tester, 'Activity setting (optional)', 'Outdoor');
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')),
      matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    expect(find.text('Outdoor tennis: measured court bank'), findsOneWidget);
    await tap(tester, 'Outdoor tennis: measured court bank');
    for (final entry in const {
      'tc_count': '2', 'tc_doubles': '10.97', 'tc_singles': '8.23', 'tc_length': '23.77',
      'tc_service': '6.4', 'tc_mark': '0.1', 'tc_post': '0.914', 'tc_side': '3', 'tc_south_end': '6',
      'tc_north_end': '7', 'tc_gap': '4', 'tc_west': '2', 'tc_south': '3',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Project information'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Outdoor courts');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.brief!.taxonomy!.spaceQuantities, isEmpty);
    expect(saved.brief!.requirements!.answers['tc_count'], 2);
    expect(find.text('Outdoor tennis court CAD'), findsOneWidget);
    expect(find.text('Share tennis court DXF'), findsOneWidget);
  });

  testWidgets('road uses route inputs and does not require building plot fields', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Transport infrastructure');
    await tap(tester, 'Road');
    await tap(tester, 'Continue'); // Missing measured corridor inputs.
    expect(find.text('Configuration'), findsOneWidget);
    expect(find.byKey(const ValueKey('Plot geometry (required)')), findsNothing);
    await enterField(tester, 'route_length', '1200.5');
    await enterField(tester, 'right_of_way', '12');
    await enterField(tester, 'transport_survey', 'Survey A / local access road');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'New road');
    await tap(tester, 'Continue');
    final alignment = find.byKey(const ValueKey('concept_straight_alignment'));
    await tester.ensureVisible(alignment);
    await tester.tap(find.descendant(of: alignment, matching: find.byType(DropdownButtonFormField<String>)));
    await tester.pumpAndSettle();
    await tap(tester, 'Confirmed straight measured alignment');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['route_length'], 1200.5);
    expect(projects.projects.single.brief!.taxonomy!.plotShapeId, isNull);
    expect(find.text('Concept zoning CAD'), findsOneWidget);
    expect(find.text('Share zoning DXF'), findsOneWidget);
  });

  testWidgets('bedroom count with no preset automatically opens the generated plan', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Residential');
    await tap(tester, 'House / low-rise dwelling');
    await tap(tester, 'Independent House');
    await tap(tester, 'Continue');
    expect(find.text('Configuration'), findsOneWidget);
    expect(find.text('Select an option.'), findsAtLeastNWidgets(1));
    await enterHomeSite(tester, width: '30', depth: '40');
    expect(find.textContaining('Plot: 1200 sqft'), findsOneWidget);
    await enterField(tester, 'bedrooms', '2');
    await enterHomeBasics(tester);
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Test House');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.name, 'Test House');
    expect(projects.projects.single.brief!.taxonomy!.configurationId, isNull);
    expect(projects.projects.single.brief!.requirements!.answers['bedrooms'], 2);
    expect(projects.projects.single.brief!.taxonomy!.scenarioId,
      'residential/houses/independent_house/2_bhk/floors_1/parking_none');
    expect(find.text('Automatic floor plan'), findsOneWidget);
    expect(find.text('2 BHK concept • South entry'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    expect(find.text('No plan generated'), findsNothing);
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
