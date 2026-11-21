import 'package:architect_engine/data/detailed_cad_fields.dart';
import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:architect_engine/screens/lap_pool_cad_screen.dart';
import 'package:architect_engine/services/lap_pool_cad_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief pool({Map<String,Object> edits = const {}, String type = 'swimming_pool', String configuration = 'outdoor'}) => ProjectBrief(
  features: const [], parking: ProjectParking.none,
  taxonomy: TaxonomySelection(version: projectTaxonomyVersion, categoryId: 'institutional', subcategoryId: 'sports',
    typeId: type, configurationId: configuration, plotShapeId: 'rectangular'),
  requirements: ProjectRequirementsSnapshot(version: requirementsSchemaVersion, answers: {
    'cad_output': 'lap_pool_measured', 'lp_length': 25, 'lp_lanes': 6, 'lp_lane_width': 2, 'lp_side_margin': .5,
    'lp_side_deck': 2, 'lp_south_deck': 2.5, 'lp_north_deck': 2.5, 'lp_west': 3, 'lp_south': 4,
    'lp_shallow_depth': 1.2, 'lp_deep_depth': 1.8, 'lp_shallow_flat': 8, 'lp_deep_flat': 5, 'lp_max_grade': 5,
    ...edits,
  }));

void main() {
  const widthFt = 24 / .3048, depthFt = 39 / .3048;
  LapPoolCadResult run(ProjectBrief brief) => LapPoolCadGenerator().generate(brief,widthFt:widthFt,depthFt:depthFt);

  test('mode is explicitly opted into and survives persistence', () {
    expect(cadOutputOptions(warehouseLoading:false).options.map((o) => o.id),isNot(contains('lap_pool_measured')));
    expect(cadOutputOptions(warehouseLoading:false,lapPool:true).options.map((o) => o.id),contains('lap_pool_measured'));
    expect(LapPoolCadGenerator.requested(ProjectBrief.fromMap(pool().toMap())),isTrue);
  });

  test('generates measured lanes and a true-scale floor with analytic water volume', () {
    final r = run(pool());
    expect(r.issue,isNull);
    expect((r.lanes,r.widthMm,r.lengthMm,r.deckWidthMm,r.deckLengthMm),(6,13000,25000,17000,30000));
    expect(r.grade,5);
    expect(r.volumeM3,closeTo(475.8,1e-9));
    final plan = r.plan!, section = r.section!;
    final lanes = plan.lines.where((l) => l.layer == 'POOL_LANES').toList();
    expect(lanes.map((l) => l.start.x),[5500,7500,9500,11500,13500,15500,17500]);
    expect(lanes.map((l) => (l.start.y,l.end.y)),everyElement((6500,31500)));
    final planBreaks = plan.lines.where((l) => l.layer == 'POOL_BREAKS');
    expect(planBreaks.map((l) => l.start.y),[14500,26500]);
    final floor = section.lines.where((l) => l.layer == 'POOL_FLOOR').toList();
    expect(floor.length,5);
    expect((floor[2].start.x,floor[2].start.y,floor[2].end.x,floor[2].end.y),(8000,-1200,20000,-1800));
    expect(plan.toDxf(),contains('POOL_DECK'));
    expect(section.toDxf(),contains('GRADE 5.000% / WATER VOLUME 475.800 M3'));
  });

  test('exact setbacks fit and zero side margin does not duplicate the water outline', () {
    final r = run(pool(edits:{'lp_side_margin':0, 'right_setback':5, 'rear_setback':5}));
    expect(r.issue,isNull);
    expect(r.plan!.lines.where((l) => l.layer == 'POOL_LANES').length,5);
  });

  test('invalid dimensions block both drawings and explain why', () {
    for (final (brief,message) in [
      (pool(type:'playground'),'Select Swimming Pool'),
      (pool(configuration:'indoor'),'Use one outdoor pool'),
      (pool(edits:{'lp_lanes':6.5}),'Enter measured'),
      (pool(edits:{'right_setback':4.001}),'right plot edge'),
      (pool(edits:{'lp_deep_depth':1.2}),'greater water depth'),
      (pool(edits:{'lp_deep_flat':17}),'no positive length'),
      (pool(edits:{'lp_max_grade':4.99}),'exceeds the supplied'),
    ]) {
      final r = run(brief);
      expect(r.issue,contains(message));
      expect(r.plan,isNull);
      expect(r.section,isNull);
    }
  });

  testWidgets('switches DXF sheets and blocks export on a steep transition',(tester) async {
    await tester.binding.setSurfaceSize(const Size(800,1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:LapPoolCadScreen(name:'Lap pool',brief:pool(),widthFt:widthFt,depthFt:depthFt)));
    expect(find.text('Share pool plan DXF'),findsOneWidget);
    await tester.tap(find.text('Longitudinal section'));
    await tester.pumpAndSettle();
    expect(find.text('Share pool section DXF'),findsOneWidget);
    await tester.pumpWidget(MaterialApp(home:LapPoolCadScreen(key:const ValueKey('invalid'),name:'Lap pool',
      brief:pool(edits:{'lp_max_grade':4}),widthFt:widthFt,depthFt:depthFt)));
    expect(find.textContaining('exceeds the supplied'),findsOneWidget);
    expect(find.text('Share pool section DXF'),findsNothing);
    expect(find.text('Share pool plan DXF'),findsNothing);
  });
}
