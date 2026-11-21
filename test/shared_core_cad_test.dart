import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/shared_core_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/shared_core_cad_generator.dart';
import 'package:architect_engine/services/tower_plan_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief shared({Map<String, Object> edits = const {}, Map<String, int> spaces = const {}, int floors = 2,
  String type = 'office_plus_retail', String config = 'vertical_mixed_use'}) => ProjectBrief(
  floorCount: floors, parking: ProjectParking.none, features: const [], taxonomy: TaxonomySelection(version: projectTaxonomyVersion,
    categoryId: 'mixed_use', subcategoryId: 'mixed_development', typeId: type, configurationId: config,
    plotShapeId: 'rectangular', spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'shared_core_shop_office', 'cad_plate_width': 13, 'cad_plate_depth': 18, 'cad_wall': .2, 'cad_door': 1,
    'cad_offset_left': 3, 'cad_offset_front': 4,
    'g1_width': 2.2, 'g1_height': 3.4, 'g1_risers': 20, 'g1_going': .28, 'g1_landing': 1.4,
    'sc_front_lobby': 3, 'sc_upper_lobby': 2, 'sc_shaft': 1.5, 'sc_approach': 1.6,
    'sc_sales_depth': 11, 'sc_meeting_depth': 5, 'mixed_components': ['retail', 'office'],
    'mixed_levels': ['ground', 'office'], ...edits,
  }));

void main() {
  TowerResult run(ProjectBrief brief, [String facing = 'South']) =>
    SharedCoreCadGenerator().generate(brief, widthFt: 95, depthFt: 110, facing: facing);
  bool same(PlanRect a, PlanRect b) => a.contains(b) && b.contains(a);
  bool touches(PlanRect a, PlanRect b) =>
    ((a.left == b.right || a.right == b.left) && a.bottom < b.top && b.bottom < a.top) ||
    ((a.bottom == b.top || a.top == b.bottom) && a.left < b.right && b.left < a.right);
  const stair = 'shared_stair', shaft = 'shared_shaft', lobby = 'shared_lobby', upLobby = 'upper_core_lobby';
  const sales = 'shared_sales', stock = 'shared_stock', meeting = 'shared_meeting', office = 'shared_office';
  const outside = AutomaticFloorPlan.entry;

  test('reopened two-floor brief uses one shared approach, vertically aligned stair and sealed shaft', () {
    final persisted = ProjectBrief.fromMap(shared().toMap())!;
    expect(SharedCoreCadGenerator.requested(persisted), isTrue);
    for (final facing in ['South', 'East', 'North', 'West']) {
      final result = run(persisted, facing);
      expect(result.issues, isEmpty, reason: '$facing: ${result.issues}');
      final ground = result.sheets.first, upper = result.sheets.last;
      expect(result.sheets.length, 2);
      expect(same(ground.plan.footprint, upper.plan.footprint), isTrue);
      final g = {for (final r in ground.plan.rooms) r.id: r.bounds};
      final u = {for (final r in upper.plan.rooms) r.id: r.bounds};
      expect(same(g[stair]!, u[stair]!) && same(g[shaft]!, u[shaft]!), isTrue);
      final doors = ground.plan.openings, upstairs = upper.plan.openings;
      expect(doors.map((o) => (o.from, o.to)), unorderedEquals([(outside, lobby), (lobby, sales), (lobby, stair), (sales, stock)]));
      expect(upstairs.map((o) => (o.from, o.to)), unorderedEquals([(stair, upLobby), (upLobby, office), (office, meeting)]));
      expect(validatePlanGeometry(ground.plan, sealedRooms: {shaft, 'reserve_core_rear'}), isNull);
      expect(validatePlanGeometry(upper.plan, indoorSeed: stair, sealedRooms: {shaft, 'reserve_core_front'}), isNull);
      expect(ground.plan.stairs.single.up, isTrue);
      expect(upper.plan.stairs.single.up, isFalse);
      expect(ground.plan.stairs.single.riseMm, 170);
      expect(ground.plan.stairs.single.strokes.take(20), orderedEquals(upper.plan.stairs.single.strokes.take(20)));
      final rotated = facing == 'East' || facing == 'West';
      expect(rotated ? g[stair]!.width : g[stair]!.depth, 8120);
      expect(rotated ? g[stair]!.depth : g[stair]!.width, 2200);
      expect(rotated ? u[shaft]!.width : u[shaft]!.depth, 1500);
      expect(rotated ? g[sales]!.width : g[sales]!.depth, 11000);
      expect(rotated ? u[meeting]!.width : u[meeting]!.depth, 5000);
      final approach = ground.siteZones.singleWhere((z) => z.id == 'sc_walk').bounds;
      final entry = doors.singleWhere((o) => o.from == outside).bounds;
      expect(touches(approach, entry) && ground.plan.plot.contains(approach), isTrue);
      expect(ground.plan.footprint.overlaps(approach), isFalse);
      expect(rotated ? approach.depth : approach.width, 1600);
      expect(upper.siteZones.where((z) => z.id == 'sc_walk'), isEmpty);
      final drawing = FloorPlanCad.combined(result.sheets.map((s) => FloorPlanCad.fromPlan(s.plan, siteZones: s.siteZones))).toDxf();
      for (final label in ['SHARED_CORE_APPROACH', 'SHARED_CORE_LOBBY', 'SHARED_CORE_SHAFT', 'UP - 20 RISERS', 'DOWN - 20 RISERS']) {
        expect(drawing, contains(label));
      }
    }
  });

  test('selector is opt-in and shop-cum-office G+1 supports wing area targets', () {
    expect(cadOutputOptions(warehouseLoading: false, sharedCore: true).options.map((o) => o.id), contains('shared_core_shop_office'));
    expect(cadOutputOptions(warehouseLoading: false).options.map((o) => o.id), isNot(contains('shared_core_shop_office')));
    expect(run(shared(type: 'shop_cum_office', edits: {'sco_layout': 'g1', 'shop_area': 175, 'office_area': 165})).sheets.length, 2);
  });

  test('programme, setbacks, stair and upper workspace conflicts block both sheets', () {
    for (final (brief, issue) in [
      (shared(floors: 1), 'single vertical G+1'),
      (shared(type: 'residential_plus_retail'), 'Select Office + Retail'),
      (shared(edits: {'mixed_separation': ['entries']}), 'one shared lobby'),
      (shared(edits: {'lift_plan': 'now'}), 'No lifts'),
      (shared(spaces: {'service_loading': 1}), 'separate Space selections'),
      (shared(edits: {'right_setback': 20}), 'right setback'),
      (shared(edits: {'fsi_limit': .2}), 'Both gross floors'),
      (shared(edits: {'sc_approach': 2.5}), 'approach must fit the core'),
      (shared(edits: {'g1_landing': .8}), 'full door swing'),
      (shared(edits: {'g1_going': .5}), 'do not fit together'),
      (shared(edits: {'sc_meeting_depth': 15.2}), 'upper lobby must overlap'),
      (shared(edits: {'office_area': 200}), 'smaller than the supplied target'),
    ]) {
      final result = run(brief);
      expect(result.sheets, isEmpty, reason: issue);
      expect(result.issues.single, contains(issue));
    }
  });

  testWidgets('preview switches floors and blocks all DXF on a failed fit', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SharedCoreCadScreen(name: 'Shop-office brief', brief: shared(),
      widthFt: 95, depthFt: 110, facing: 'South')));
    expect(find.text('Shop below office CAD'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First floor — Office and meeting').last);
    await tester.pumpAndSettle();
    expect(find.text('First floor · Office and meeting'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share all sheets DXF'), 250);
    expect(find.textContaining('DOWN: 20 risers'), findsOneWidget);
    expect(find.text('Share selected DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: SharedCoreCadScreen(key: const ValueKey('blocked'), name: 'Shop-office brief',
      brief: shared(edits: {'g1_going': .5}), widthFt: 95, depthFt: 110, facing: 'South')));
    expect(find.textContaining('do not fit together'), findsOneWidget);
    expect(find.text('Share selected DXF'), findsNothing);
    expect(find.text('Share all sheets DXF'), findsNothing);
  });
}
