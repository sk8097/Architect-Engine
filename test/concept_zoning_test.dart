import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/services/concept_zoning_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief brief(String category, String group, String type, {bool linear = false, int? levels,
  Map<String, Object> answers = const {}, Map<String, Map<String, Object>> zones = const {},
  Map<String, int>? quantities, String shape = 'rectangular'}) => ProjectBrief(
  floorCount: levels, parking: null, features: const [],
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: category, subcategoryId: group,
    typeId: type, plotShapeId: linear ? null : shape,
    spaceQuantities: quantities ?? {for (final id in zones.keys) id: 1}),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: answers,
    spaceDetails: zones, customSpaces: {for (final id in zones.keys) id: 'Measured $id'}),
);

void main() {
  final generator = ConceptZoningGenerator();
  ZoningResult run(ProjectBrief input) => generator.generate(input, widthFt: 100, depthFt: 100, facing: 'North');

  test('every catalogue type has a measured concept path, not just a registered label', () {
    for (final category in projectTaxonomy) {
      for (final group in category.groups) {
        for (final type in group.types) {
          final linear = usesLinearSite(category.id, group.id, type.id);
          final input = brief(category.id, group.id, type.id, levels: linear ? null : 1, linear: linear,
            answers: linear ? {'route_length': 100, 'right_of_way': 20, 'concept_straight_alignment': 'confirmed'} : {},
            zones: {'measured': {'width': 5, 'length': 6}});
          final result = run(input);
          expect(result.issues, isEmpty, reason: '${category.id}/${group.id}/${type.id}');
          final sheet = result.sheets.single;
          expect(sheet.zones.single.bounds.width, 5000);
          expect(sheet.zones.single.bounds.depth, 6000);
          expect(sheet.envelope.contains(sheet.zones.single.bounds), isTrue);
          final drawing = FloorPlanCad.fromZoning(sheet);
          expect(drawing.toDxf(), contains('CONCEPT ZONING'));
          expect(drawing.lines.any((line) => line.layer == 'WALLS'), isFalse);
        }
      }
    }
  });

  test('clear dimensions, setbacks, required edge and same-floor adjacency are enforced', () {
    final result = run(brief('industrial', 'logistics', 'general_warehouse', levels: 1,
      answers: {'front_setback': 3, 'left_setback': 2}, zones: {
        'a': {'width': 12, 'length': 6, 'access': 'service', 'zone_edge': 'front', 'adjacent_required': ['b']},
        'b': {'width': 12, 'length': 7},
      }));
    expect(result.issues, isEmpty);
    final sheet = result.sheets.single;
    expect(sheet.envelope.left, 2000);
    expect(sheet.zones.first.bounds.bottom, 3000);
    final (a, b) = (sheet.zones[0].bounds, sheet.zones[1].bounds);
    expect(a.overlaps(b), isFalse);
    expect(a.right == b.left || a.top == b.bottom, isTrue);
    expect(FloorPlanCad.fromZoning(sheet).lines.any((line) => line.layer == 'ZONES_SERVICE'), isTrue);
    final missing = run(brief('industrial', 'logistics', 'general_warehouse', zones: {'a': {'area_min': 10}}));
    expect(missing.issues.single, contains('clear width and length'));
  });

  test('upper level uses its supplied envelope and exports a distinct sheet', () {
    final result = run(brief('commercial', 'office', 'corporate_office', levels: 2,
      answers: {'zoning_width_1': 10, 'zoning_depth_1': 12}, zones: {
        'a': {'width': 5, 'length': 5, 'access': 'public'},
        'b': {'width': 4, 'length': 6, 'floor_level': 'Floor 1'},
      }));
    expect(result.issues, isEmpty);
    expect(result.sheets, hasLength(2));
    expect(result.sheets.last.envelope.width, 10000);
    expect(result.sheets.last.envelope.depth, 12000);
    final set = FloorPlanCad.combined(result.sheets.map(FloorPlanCad.fromZoning));
    expect(set.toDxf(), contains('FLOOR 1'));
    expect(set.toDxf(), contains('GROUND'));
  });

  test('unconfirmed alignment and irregular survey area do not produce invented geometry', () {
    final road = run(brief('infrastructure', 'transport', 'road', linear: true,
      answers: {'right_of_way': 15, 'route_length': 1234.5}));
    expect(road.sheets, isEmpty);
    expect(road.issues.single, contains('confirm a straight'));
    final measured = run(brief('infrastructure', 'transport', 'road', linear: true,
      answers: {'right_of_way': 15, 'route_length': 1234.5, 'concept_straight_alignment': 'confirmed'}));
    expect(measured.sheets.single.envelope.depth, 15000);
    expect(FloorPlanCad.fromZoning(measured.sheets.single).toDxf(), contains('STA 1+234.500'));
    expect(run(brief('rural', 'farm', 'dairy_farm', shape: 'irregular', zones: {
      'a': {'width': 5, 'length': 5},
    })).issues.single, contains('rectangular or square'));
  });

  test('measured corridor bands keep their widths and reject oversubscribed ROW', () {
    final accepted = run(brief('infrastructure','transport','road', linear: true, answers: {
      'route_length': 140, 'right_of_way': 10, 'concept_straight_alignment': 'confirmed',
      'corridor_bands': 'Sidewalk:1.5; Roadway:6; Sidewalk:1.5',
    }));
    expect(accepted.issues, isEmpty);
    final sheet = accepted.sheets.single;
    expect(sheet.zones.map((b) => b.bounds.depth), [1500, 6000, 1500]);
    expect(sheet.zones.map((b) => b.bounds.bottom), [0, 1500, 7500]);
    expect(FloorPlanCad.fromZoning(sheet).toDxf(), contains('CORRIDOR_BANDS'));
    final rejected = run(brief('infrastructure','transport','road', linear: true, answers: {
      'route_length': 140, 'right_of_way': 8, 'concept_straight_alignment': 'confirmed',
      'corridor_bands': 'Sidewalk:1.5; Roadway:6; Sidewalk:1.5',
    }));
    expect(rejected.sheets, isEmpty);
    expect(rejected.issues.single, contains('exceed the right-of-way'));
  });

}
