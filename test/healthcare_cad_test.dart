import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/automatic_floor_plan.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/healthcare_cad_screen.dart';
import 'package:architect_engine/services/automatic_floor_plan_generator.dart';
import 'package:architect_engine/services/floor_plan_cad.dart';
import 'package:architect_engine/services/healthcare_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief clinic({String type = 'general_clinic', Map<String, Object> values = const {},
  Map<String, Map<String,Object>> details = const {}, String configuration = 'outpatient'}) {
  final spaces = <String, Map<String,Object>>{
    'waiting': {'width': 6.9, 'length': 5, 'hc_route': 'patient', 'cad_window': 1.7},
    'consultation': {'width': 4, 'length': 4, 'hc_route': 'patient'},
    'clinical_store': {'width': 3, 'length': 4, 'hc_route': 'service'},
    ...details,
  };
  return ProjectBrief(floorCount: 1, parking: ProjectParking.none, features: const [],
    taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'healthcare',
      typeId: type, plotShapeId: 'rectangular', configurationId: configuration,
      spaceQuantities: {for (final id in spaces.keys) id: 1}),
    requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, spaceDetails: spaces,
      answers: {'cad_output': 'clinic_separated', 'cad_plate_width': 30, 'cad_plate_depth': 16,
        'cad_wall': .2, 'cad_corridor': 1.4, 'cad_door': 1, 'cad_offset_left': 4, 'cad_offset_front': 3,
        'hc_patient_width': 16, 'hc_service_corridor': 1.7, 'hc_service_entry': 'opposite',
        'hc_transfer': 'not_required', 'clinical_departments': ['opd'], 'consult_rooms': 1,
        'left_setback': 3, 'right_setback': 2, 'front_setback': 3, 'rear_setback': 4, ...values}));
}

void main() {
  final generator = HealthcareCadGenerator();
  ClinicCadResult run(ProjectBrief brief, [String side = 'South']) =>
    generator.generate(brief, widthFt: 150, depthFt: 100, facing: side);

  test('independent entrances, corridors and outer facade window fit all cardinal frontages', () {
    for (final side in ['South','North','East','West']) {
      final result = run(clinic(), side);
      expect(result.issue, isNull, reason: side);
      final plan = result.plan!;
      expect(validatePlanPartition(plan), isNull);
      final p = plan.openings.singleWhere((o) => o.from == AutomaticFloorPlan.entry && o.to == 'patient_internal_passage').bounds;
      final s = plan.openings.singleWhere((o) => o.from == AutomaticFloorPlan.entry && o.to == 'service_internal_passage').bounds;
      final plate = plan.footprint;
      final positions = switch (side) {
        'South' => (p.bottom, s.top, plate.bottom, plate.top),
        'North' => (p.top, s.bottom, plate.top, plate.bottom),
        'East' => (p.right, s.left, plate.right, plate.left),
        _ => (p.left, s.right, plate.left, plate.right),
      };
      expect(positions.$1, positions.$3, reason: side);
      expect(positions.$2, positions.$4, reason: side);
      expect(plan.openings.where((o) => o.kind == PlanOpeningKind.door && o.from != AutomaticFloorPlan.entry)
        .every((o) => o.from.split('_').first == o.to.split('_').first), isTrue);
      expect(plan.rooms.singleWhere((r) => r.id == 'patient_internal_passage').bounds.area, 1400 * 15600);
      expect(plan.rooms.singleWhere((r) => r.id == 'service_internal_passage').bounds.area, 1700 * 15600);
      final window = plan.openings.singleWhere((o) => o.kind == PlanOpeningKind.window).bounds;
      expect(window.left == plate.left || window.right == plate.right || window.bottom == plate.bottom || window.top == plate.top, isTrue);
      final drawing = FloorPlanCad.fromPlan(plan);
      expect(drawing.toDxf(), contains('SEPARATE CLINIC ROUTES'));
      expect(drawing.arcs.where((arc) => arc.layer == 'PATIENT_ROUTE'), hasLength(3));
      expect(drawing.arcs.where((arc) => arc.layer == 'SERVICE_ROUTE'), hasLength(2));
    }
  });

  test('same frontage supports distinct, non-overlapping entrances', () {
    final result = run(clinic(values: {'hc_service_entry': 'same'}));
    expect(result.issue, isNull);
    final plan = result.plan!;
    final entries = plan.openings.where((o) => o.kind == PlanOpeningKind.door && o.from == AutomaticFloorPlan.entry).toList();
    expect(entries, hasLength(2));
    expect(entries.every((o) => o.bounds.bottom == plan.footprint.bottom), isTrue);
    expect(entries[0].bounds.overlaps(entries[1].bounds), isFalse);
  });

  test('unsupported clinical flows, crossing dependencies and measured limits have no output', () {
    expect(run(clinic(type: 'general_hospital')).issue, contains('listed outpatient clinics'));
    expect(run(clinic(configuration: 'inpatient')).issue, contains('only supports outpatient'));
    expect(run(clinic(values: {'hc_transfer': 'required'})).issue, contains('cannot provide an internal transfer'));
    expect(run(clinic(values: {'coverage_limit': 20})).issue, contains('Combined clinic footprint'));
    expect(run(clinic(details: {'isolation': {'hc_route': 'patient','width': 3,'length': 4}})).issue, contains('specialist clinical layout'));
    final crossing = run(clinic(details: {
      'consultation': {'hc_route': 'patient','width': 4,'length': 4,'adjacent_required': ['clinical_store']},
    }));
    expect(crossing.issue, contains('across the patient/service divider'));
    expect(crossing.plan, isNull);
    expect(run(clinic(details: {'clinical_store': {'hc_route':'patient','width':3,'length':4}})).issue, contains('conflicts with the room'));
  });

  testWidgets('clinic preview has export only after the independent routes validate', (tester) async {
    Future<void> preview(ProjectBrief brief) async {
      await tester.pumpWidget(MaterialApp(home: HealthcareCadScreen(key: ObjectKey(brief), name: 'Clinic test',
        brief: brief, widthFt: 150, depthFt: 100, facing: 'South')));
      await tester.pumpAndSettle();
    }
    await preview(clinic());
    expect(find.text('Clinic route CAD'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsOneWidget);
    await preview(clinic(values: {'hc_transfer': 'required'}));
    expect(find.textContaining('cannot provide an internal transfer'), findsOneWidget);
    expect(find.text('Save or share DXF'), findsNothing);
  });
}
