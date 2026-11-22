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
    await tap(tester, 'Continue');
    expect(find.text('Enter a project name.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'North View');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    final quantity = find.byType(TextFormField).first;
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '0');
    await tap(tester, 'Continue');
    expect(find.text('Enter a positive quantity.'), findsOneWidget);
    await tester.enterText(quantity, '2');
    await tap(tester, 'Continue');
    await goToReview(tester);
    expect(find.text('Review & Generate'), findsOneWidget);
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

  testWidgets('passenger shelter mode saves the roof inputs and opens the plan', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Institutional & Public Utility');
    await tap(tester, 'Sports / recreation / public amenities');
    await tap(tester, 'Passenger Shelter');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '12');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '18');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Passenger shelter: measured canopy and headroom');
    for (final entry in const {
      'sh_bays': '3', 'sh_pitch': '3.2', 'sh_span': '3.6', 'sh_post': '0.2', 'sh_oh_w': '1', 'sh_oh_e': '0.8',
      'sh_oh_end': '0.6', 'sh_w_z': '3.1', 'sh_e_z': '2.5', 'sh_roof_d': '0.18', 'sh_min_walk': '3.4',
      'sh_min_head': '2.6', 'sh_min_eave': '2.5', 'sh_west': '2', 'sh_south': '3',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Passenger canopy');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['sh_bays'], 3);
    expect(find.text('Passenger shelter canopy CAD'), findsOneWidget);
    expect(find.text('Share canopy plan DXF'), findsOneWidget);
  });

  testWidgets('measured plaza paving saves without generic landscape survey fields', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Urban Plaza');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '12');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '8');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Urban plaza: centred paving grid and cut schedule');
    for (final entry in const {
      'pav_w': '7.04', 'pav_l': '4.23', 'pav_west': '2', 'pav_south': '1', 'pav_unit_x': '0.6',
      'pav_unit_y': '0.4', 'pav_joint': '0.005', 'pav_min_x': '0.2', 'pav_min_y': '0.12',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Paved plaza');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['pav_joint'], .005);
    expect(find.text('Urban plaza paving CAD'), findsOneWidget);
    expect(find.text('Share paving plan DXF'), findsOneWidget);
  });

  testWidgets('long and triple jump runway saves with measured event dimensions', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Institutional & Public Utility');
    await tap(tester, 'Sports / recreation / public amenities');
    await tap(tester, 'Sports Complex');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '10');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '75');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Athletics: measured long and triple jump runway');
    for (final entry in const {
      'jr_run_l': '55', 'jr_run_w': '1.22', 'jr_pit_l': '9', 'jr_pit_w': '3', 'jr_long_offset': '2',
      'jr_triple_offset': '11', 'jr_long_run_min': '53', 'jr_triple_run_min': '44', 'jr_long_far_min': '11',
      'jr_triple_far_min': '20', 'jr_side': '1.5', 'jr_south_reserve': '2', 'jr_north_reserve': '4',
      'jr_west': '2', 'jr_south': '2',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Jump runway');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['jr_triple_offset'], 11);
    expect(find.text('Share jump runway DXF'), findsOneWidget);
    expect(find.text('Share take-off schedule CSV'), findsOneWidget);
  });

  testWidgets('cinema seating saves measured banks without generic service inputs', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Commercial');
    await tap(tester, 'Business / service facilities');
    await tap(tester, 'Cinema / Entertainment');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '18');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '20');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Cinema: measured seat banks and rear flexible bays');
    for (final entry in const {
      'cs_hall': '14', 'cs_rows': '8', 'cs_seat_w': '0.55', 'cs_seat_d': '0.6', 'cs_pitch': '1.05', 'cs_row_gap': '0.45',
      'cs_cap': '10', 'cs_target': '144', 'cs_centre': '1.6', 'cs_side': '1.2', 'cs_rear': '1.4', 'cs_aisle_min': '1.2',
      'cs_bays': '3', 'cs_bay_w': '1.1', 'cs_bay_d': '1.5', 'cs_front': '4', 'cs_screen_y': '0.5', 'cs_screen_w': '8',
      'cs_west': '2', 'cs_south': '2.5',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Cinema hall');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['cs_target'], 144);
    expect(find.text('Share seating plan DXF'), findsOneWidget);
    expect(find.text('Share seating schedule CSV'), findsOneWidget);
  });

  testWidgets('outdoor switchback stair saves both landings without generic room fields', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Public Park');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '7');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '10');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Public space: measured switchback stair');
    for (final entry in const {
      'ss_datum': 'Local RL', 'ss_lower': '100', 'ss_upper': '103.75', 'ss_min_riser': '0.14', 'ss_max_riser': '0.17',
      'ss_going': '0.29', 'ss_width': '1.5', 'ss_gap': '0.3', 'ss_end': '1.6', 'ss_turn': '1.8', 'ss_west': '1', 'ss_south': '1.2',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Park stair');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['ss_upper'], 103.75);
    expect(find.text('Share stair plan DXF'), findsOneWidget);
  });

  testWidgets('public rain garden saves and draws from measured geometry', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Public Garden');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '14');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '18');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Public garden: rain-garden ponding and media layers');
    for (final entry in const {
      'rg_bed_w': '6', 'rg_bed_l': '8', 'rg_slope_we': '3', 'rg_slope_sn': '4', 'rg_pond': '0.25',
      'rg_free': '0.15', 'rg_media': '0.6', 'rg_agg': '0.25', 'rg_reserve': '1.2', 'rg_reserve_min': '0.9',
      'rg_storage_min': '15.25', 'rg_west': '1', 'rg_south': '2',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Public rain garden');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['rg_storage_min'], 15.25);
    expect(find.text('Share rain garden plan DXF'), findsOneWidget);
  });

  testWidgets('pedestrian underpass saves both surveyed profiles in the specialist mode', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Transport infrastructure');
    await tap(tester, 'Underpass');
    final mode = find.descendant(of: find.byKey(const ValueKey('underpass_mode')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Surveyed pedestrian underpass: grade and headroom');
    expect(find.byKey(const ValueKey('route_length')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Pedestrian underpass');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    for (final entry in const {
      'up_grid': 'Example grid', 'up_datum': 'Local RL', 'up_axis': '500000,2000000;500060,2000080',
      'up_walk': '5,100.8;25,99.8;45,99.6;65,99.8;85,100.8', 'up_soffit': '23,102.5;35,102.25;55,102.25;67,102.5',
      'up_clear': '4', 'up_min_width': '4', 'up_wall': '0.3', 'up_corridor': '5', 'up_head': '2.55', 'up_grade': '5',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.requirements!.answers['up_head'], 2.55);
    expect(find.text('Share underpass plan DXF'), findsOneWidget);
  });

  testWidgets('streetscape wall saves sampled levels and opens measured CAD', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Streetscape');
    Future<void> pick(String id, String label) async {
      final dropdown = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(DropdownButtonFormField<String>));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tap(tester, label);
    }
    await pick('stepped_wall_mode', 'Surveyed stepped landscape wall: profile and quantities');
    expect(find.byKey(const ValueKey('route_length')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Landscape wall');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    await pick('sw_back_side', 'Left');
    for (final entry in const {
      'sw_grid': 'Example grid', 'sw_datum': 'Local RL', 'sw_axis': '1000,2000;1060,2080',
      'sw_ground': '10,100,101;40,100.3,101.6;70,100.6,102.1;90,100.8,102.4',
      'sw_steps': '35,99.5,101.7;65,99.8,102.3;90,100.1,102.6', 'sw_width': '0.4',
      'sw_embed': '0.45', 'sw_top_margin': '0.2', 'sw_visible_max': '2.05',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.requirements!.answers['sw_embed'], .45);
    expect(find.text('Share wall plan DXF'), findsOneWidget);
    expect(find.text('Share wall quantity CSV'), findsOneWidget);
  });

  testWidgets('surveyed street lighting saves pole locations without generic utility fields', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Energy / utilities / communications');
    await tap(tester, 'Street Lighting Network');
    Future<void> pick(String id, String label) async {
      final dropdown = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(DropdownButtonFormField<String>));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tap(tester, label);
    }
    await pick('street_light_mode', 'Surveyed pole row: equal spacing and exclusions');
    expect(find.byKey(const ValueKey('route_length')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Street poles');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    await pick('sl_side', 'Left');
    for (final entry in const {
      'sl_grid': 'Example grid', 'sl_axis': '1000,2000;1060,2080', 'sl_offset': '3', 'sl_start': '10',
      'sl_end': '90', 'sl_min': '14', 'sl_max': '22', 'sl_exclusions': '29,31',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.requirements!.answers['sl_exclusions'], '29,31');
    expect(find.text('Share pole layout DXF'), findsOneWidget);
    expect(find.text('Share pole coordinates CSV'), findsOneWidget);
  });

  testWidgets('telecom duct bank saves levels and crossings without generic equipment inputs', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Energy / utilities / communications');
    await tap(tester, 'Telecom Network');
    final mode = find.descendant(of: find.byKey(const ValueKey('duct_bank_mode')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Surveyed duct bank: cover and utility crossings');
    expect(find.byKey(const ValueKey('route_length')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Telecom run');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    for (final entry in const {
      'db_grid': 'Example grid', 'db_datum': 'Local RL', 'db_axis': '500000,2000000;500060,2000080',
      'db_levels': '10,102,100;40,101.1,100.2;90,103,100.7', 'db_width': '1.2', 'db_depth': '0.6',
      'db_cover': '0.9', 'db_gap': '0.3', 'db_crossings': 'U1,25,98.9,99.2;U2,70,100.9,101.05',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.requirements!.answers['db_gap'], .3);
    expect(find.text('Surveyed telecom duct bank CAD'), findsOneWidget);
    expect(find.text('Share duct-bank plan DXF'), findsOneWidget);
  });

  testWidgets('staggered refuge saves in Street without generic corridor inputs', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Transport infrastructure');
    await tap(tester, 'Street');
    final mode = find.descendant(of: find.byKey(const ValueKey('corridor_cad_mode')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Surveyed staggered pedestrian refuge');
    expect(find.byKey(const ValueKey('route_length')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Staggered crossing');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    for (final entry in const {
      'ref_grid': 'Example grid', 'ref_axis': '1000,2000;1060,2080', 'ref_ch_l': '35', 'ref_ch_r': '43',
      'ref_road_l': '7', 'ref_road_r': '7.5', 'ref_median': '4', 'ref_cross_w': '3', 'ref_walk_w': '2',
      'ref_min_w': '2', 'ref_reserve': '1', 'ref_stagger': '5', 'ref_land_l': '2.5', 'ref_land_r': '3',
      'ref_min_land': '2.5',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.requirements!.answers['ref_ch_r'], 43);
    expect(find.text('Share pedestrian refuge DXF'), findsOneWidget);
  });

  testWidgets('separated cycle track saves survey fields and opens the specialist preview', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Transport infrastructure');
    await tap(tester, 'Cycle Track');
    Future<void> pick(String id, String label) async {
      final dropdown = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(DropdownButtonFormField<String>));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tap(tester, label);
    }
    await pick('corridor_cad_mode', 'Separated cycle track: surveyed driveway crossings');
    expect(find.byKey(const ValueKey('route_length')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Cycle corridor');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    await pick('cyc_side', 'Left');
    for (final entry in const {
      'cyc_grid': 'Example grid', 'cyc_axis': '1000,2000;1060,2080',
      'cyc_limits': '10,7;40,6;90,8', 'cyc_buffer': '1.5', 'cyc_width': '3',
      'cyc_margin': '1.5', 'cyc_island': '28', 'cyc_driveways': 'D1,20,26;D2,54,62',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.requirements!.answers['cyc_driveways'], 'D1,20,26;D2,54,62');
    expect(find.text('Share cycle track DXF'), findsOneWidget);
    expect(find.text('Share driveway schedule CSV'), findsOneWidget);
  });

  testWidgets('surveyed promenade saves limit and pad records without a building footprint', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Waterfront Promenade');
    Future<void> pick(String id, String label) async {
      final dropdown = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(DropdownButtonFormField<String>));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tap(tester, label);
    }
    await pick('promenade_mode', 'Surveyed promenade: path and lookout pads');
    expect(find.byKey(const ValueKey('Plot geometry (required)')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Waterfront');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    await pick('pmr_land_side', 'Left');
    for (final entry in const {
      'pmr_grid': 'Example projected grid', 'pmr_axis': '1000,2000;1060,2080',
      'pmr_limits': '10,-1,13;40,2,12;70,0,11;100,-2,14', 'pmr_path': '5', 'pmr_width': '3',
      'pmr_shore_gap': '2', 'pmr_inland_gap': '3', 'pmr_pads': 'L1,20,55,1;L2,75,90,2',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.requirements!.answers['pmr_pads'], 'L1,20,55,1;L2,75,90,2');
    expect(find.text('Surveyed promenade CAD'), findsOneWidget);
    expect(find.text('Share promenade DXF'), findsOneWidget);
    expect(find.text('Share lookout schedule CSV'), findsOneWidget);
  });

  testWidgets('rail platform survey mode saves without a plot footprint and opens the plan', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Transport infrastructure');
    await tap(tester, 'Railway Station');
    Future<void> pick(String id, String label) async {
      final dropdown = find.descendant(of: find.byKey(ValueKey(id)), matching: find.byType(DropdownButtonFormField<String>));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tap(tester, label);
    }
    await pick('rail_platform_mode', 'Surveyed side platform: track offset and cross-section');
    expect(find.byKey(const ValueKey('Plot geometry (required)')), findsNothing);
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    await tester.enterText(find.byType(TextFormField).first, 'Straight platform');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    await pick('rp_side', 'Left');
    for (final entry in const {
      'rp_grid': 'Projected example', 'rp_datum': 'Survey datum A', 'rp_axis': '500000,2000000;500096,2000128',
      'rp_levels': '20,100,100.95;60,100.2,101.1;120,100.4,101.4', 'rp_offset': '1.8', 'rp_min_offset': '1.8',
      'rp_width': '6', 'rp_edge_band': '0.8', 'rp_back_band': '1', 'rp_walk_min': '4.2', 'rp_crossfall': '2',
      'rp_rise_min': '0.9', 'rp_rise_max': '1', 'rp_grade_max': '0.5',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    final saved = projects.projects.single;
    expect(saved.toMap()['width'], isNull);
    expect(saved.brief!.taxonomy!.plotShapeId, isNull);
    expect(saved.brief!.requirements!.answers['rp_walk_min'], 4.2);
    expect(find.text('Surveyed rail platform CAD'), findsOneWidget);
    expect(find.text('Share platform plan DXF'), findsOneWidget);
  });

  testWidgets('public toilet mode saves fixtures and opens the measured DXF preview', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Public Toilet');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '16');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '12');
    await tester.pumpAndSettle();
    final floors = find.byKey(const ValueKey('floor_count'));
    await tester.ensureVisible(floors);
    await tester.enterText(floors, '1');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Public toilet: measured rooms and clear entry');
    for (final entry in const {
      'pt_rooms': '3', 'pt_width': '3.2', 'pt_depth': '3.5', 'pt_wall': '0.2', 'pt_door': '0.95', 'pt_gallery': '1.8',
      'pt_entry': '0.9', 'pt_circle': '1.6', 'pt_center': '1.7', 'pt_wc_x': '0.25', 'pt_wc_y': '2.65', 'pt_wc_w': '0.7',
      'pt_wc_d': '0.75', 'pt_basin_x': '2.4', 'pt_basin_y': '1.1', 'pt_basin_w': '0.6', 'pt_basin_d': '0.6',
      'pt_west': '2', 'pt_south': '2',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Project information'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Public facilities');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['pt_rooms'], 3);
    expect(find.text('Public toilet block CAD'), findsOneWidget);
    expect(find.text('Share public toilet DXF'), findsOneWidget);
  });

  testWidgets('vehicle service bay wizard saves the measured lift brief', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Industrial & Warehousing');
    await tap(tester, 'Workshop');
    await tap(tester, 'Vehicle Repair');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '18');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '20');
    await tester.pumpAndSettle();
    final floors = find.byKey(const ValueKey('floor_count'));
    await tester.ensureVisible(floors);
    await tester.enterText(floors, '1');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Workshop: measured vehicle lift bays and section');
    for (final entry in const {
      'service_bays': '2', 'clear_height': '4.6', 'lv_bay_w': '4.8', 'lv_wall': '0.2', 'lv_car_w': '2.1',
      'lv_car_l': '5.2', 'lv_car_h': '1.95', 'lv_front': '1.6', 'lv_rear': '1.4', 'lv_door_w': '2.9',
      'lv_door_h': '2.45', 'lv_door_head': '0.35', 'lv_inner': '2.7', 'lv_post_w': '0.35', 'lv_post_d': '0.4',
      'lv_post_h': '4', 'lv_rise': '1.8', 'lv_side': '0.3', 'lv_outside': '0.7', 'lv_overhead': '0.6',
      'lv_apron': '4', 'lv_west': '2.5', 'lv_south': '3',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Project information'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Vehicle service');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['service_bays'], 2);
    expect(find.text('Vehicle service bay CAD'), findsOneWidget);
    expect(find.text('Share workshop plan DXF'), findsOneWidget);
  });

  testWidgets('measured athletics oval saves and opens its DXF and lane schedule', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Institutional & Public Utility');
    await tap(tester, 'Sports / recreation / public amenities');
    await tap(tester, 'Stadium');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '110');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '200');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Athletics: measured oval and one-lap staggers');
    for (final entry in const {
      'ak_lanes': '8', 'ak_straight': '84.39', 'ak_radius': '36.5', 'ak_lane_width': '1.22', 'ak_offset_1': '0.3',
      'ak_offset_other': '0.2', 'ak_runoff': '3', 'ak_west': '4', 'ak_south': '7', 'ak_target': '400', 'ak_tolerance': '0.01',
    }.entries) {
      await enterField(tester, entry.key, entry.value);
    }
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Project information'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Track');
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['ak_target'], 400);
    expect(find.textContaining('Lane 1 lap 400.001 m'), findsOneWidget);
    expect(find.text('Share athletics track DXF'), findsOneWidget);
    expect(find.text('Share lane schedule CSV'), findsOneWidget);
  });

  testWidgets('playground mode saves the Site equipment records and opens both exports', (tester) async {
    final projects = await openWizard(tester);
    await tap(tester, 'Infrastructure / Public Works');
    await tap(tester, 'Public realm / landscape / waste');
    await tap(tester, 'Playground');
    await choose(tester, 'Plot geometry (required)', 'Rectangular');
    await choose(tester, 'Plot units', 'Metres');
    await tester.enterText(find.byKey(const ValueKey('Plot width / frontage (m)')), '24');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Plot depth (m)')), '25');
    await tester.pumpAndSettle();
    final mode = find.descendant(of: find.byKey(const ValueKey('cad_output')), matching: find.byType(DropdownButtonFormField<String>));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tap(tester, 'Playground: measured equipment and clearance zones');
    await enterField(tester, 'py_path_west', '11');
    await enterField(tester, 'py_path_width', '2');
    await enterField(tester, 'py_gap', '2');
    await tap(tester, 'Continue');
    expect(find.text('Space / room program'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Project information'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Play area');
    await tap(tester, 'Continue');
    expect(find.text('Site / plot / land'), findsOneWidget);
    const equipment = 'A1,4,5,3,4,1,2,2,1; B2,5,15,2,3,2,1,1,2; C3,16,6,3,3,1,1,2,1';
    await enterField(tester, 'py_equipment', equipment);
    await goToReview(tester);
    await tap(tester, 'Save project brief');
    expect(projects.projects.single.brief!.requirements!.answers['py_equipment'], equipment);
    expect(find.text('Playground clearance CAD'), findsOneWidget);
    expect(find.text('Share playground DXF'), findsOneWidget);
    expect(find.text('Share zone schedule CSV'), findsOneWidget);
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
  for (var i = 0; i < 8 && find.text('Review & Generate').evaluate().isEmpty; i++) {
    await tap(tester, 'Continue');
  }
  expect(find.text('Review & Generate'), findsOneWidget);
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
