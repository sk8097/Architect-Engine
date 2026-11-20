import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief brief({String shape = 'rectangular', String type = 'independent_house',
    int? floors = 1, ProjectParking? parking = ProjectParking.none,
    Map<String, Object> answers = const {}, Map<String, int> spaces = const {},
    Map<String, Map<String, Object>> details = const {}}) => ProjectBrief(
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'residential',
    subcategoryId: 'houses', typeId: type, configurationId: '1_bhk',
    plotShapeId: shape, spaceQuantities: spaces),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion,
    answers: answers, spaceDetails: details),
  floorCount: floors, parking: parking, features: const [],
);

void main() {
  final generator = AutomaticFloorPlanGenerator();
  FloorPlanResult run(ProjectBrief input, {double frontage = 30, double depth = 40,
    String facing = 'South'}) => generator.generate(brief: input, frontageFt: frontage,
      depthFt: depth, facing: facing);

  test('valid rectangular plot generates connected, non-overlapping geometry in mm', () {
    final result = run(brief());
    expect(result.issues, isEmpty);
    final plan = result.plan!;
    expect(plan.plot.width, 9144);
    expect(plan.plot.depth, 12192);
    expect(plan.rooms.map((r) => r.id), unorderedEquals([
      'family_living_room', 'master_bedroom', 'closed_kitchen',
      'shared_bathroom', 'internal_passage',
    ]));
    expect(plan.openings.where((o) => o.kind == PlanOpeningKind.door), hasLength(5));
    expect(plan.openings.where((o) => o.kind == PlanOpeningKind.window), hasLength(4));
    expect(validateAutomaticFloorPlan(plan), isNull);
    expect(result.warnings.join(' '), contains('Unsupplied setbacks were not checked'));
    final withoutEntry = AutomaticFloorPlan(plot: plan.plot, footprint: plan.footprint,
      facing: plan.facing, rooms: plan.rooms, walls: [...plan.walls,
        plan.openings.singleWhere((o) => o.kind == PlanOpeningKind.door && o.from == AutomaticFloorPlan.entry).bounds,
      ], openings: plan.openings.where((o) => o.kind != PlanOpeningKind.door || o.from != AutomaticFloorPlan.entry));
    expect(validateAutomaticFloorPlan(withoutEntry), contains('entrance'));
  });

  test('cardinal frontage and supplied setbacks transform with the plot', () {
    for (final facing in ['North', 'East', 'South', 'West']) {
      final result = run(brief(answers: {'front_setback': 1.2, 'rear_setback': 1.8,
        'left_setback': 0.5, 'right_setback': 0.6}), facing: facing);
      expect(result.issues, isEmpty, reason: facing);
      final plan = result.plan!;
      final gap = switch (facing) {
        'North' => plan.plot.top - plan.footprint.top,
        'East' => plan.plot.right - plan.footprint.right,
        'West' => plan.footprint.left,
        _ => plan.footprint.bottom,
      };
      expect(gap, greaterThanOrEqualTo(1200));
      expect(validateAutomaticFloorPlan(plan), isNull);
    }
    expect(run(brief(shape: 'square'), depth: 30, facing: 'East').plan, isNotNull);
    expect(run(brief(shape: 'square'), depth: 31).issues.join(' '), contains('must match'));
  });

  test('hard room sizes and required adjacency are used, not ignored', () {
    final result = run(brief(spaces: {'master_bedroom': 1, 'family_living_room': 1}, details: {
      'master_bedroom': {'width': 3.1, 'area_unit': 'sqm', 'area_min': 10,
        'adjacent_required': ['family_living_room']},
    }));
    final bed = result.plan!.rooms.singleWhere((r) => r.id == 'master_bedroom');
    expect(bed.bounds.width, 3100);
    expect(bed.bounds.area, greaterThanOrEqualTo(10000000));
    expect(run(brief(details: {'master_bedroom': {'adjacent_required': ['closed_kitchen']}})).plan, isNull);
    expect(run(brief(details: {'master_bedroom': {'area_unit': 'sqm', 'area_min': 60}})).plan, isNull);
  });

  test('unsupported profile, missing inputs, and infeasible requests do not generate', () {
    expect(run(brief(type: 'villa')).plan, isNull);
    expect(run(brief(floors: null), facing: 'Not decided', frontage: 0).issues, hasLength(3));
    expect(run(brief(parking: ProjectParking.car)).issues.join(' '), contains('No parking'));
    expect(run(brief(answers: {'road_sides': ['n']})).issues.join(' '), contains('matching'));
    expect(run(brief(answers: {'front_setback': 12, 'rear_setback': 1})).issues.join(' '), contains('consume'));
    expect(run(brief(answers: {'coverage_limit': 10})).plan, isNull);
    expect(run(brief(spaces: {'garden': 1})).issues.join(' '), contains('Garden'));
    expect(run(brief(details: {'master_bedroom': {'priority': 'excluded'}})).issues.join(' '), contains('essential'));
    expect(run(brief(), frontage: 12, depth: 20).issues.join(' '), contains('No supported'));
  });
}
