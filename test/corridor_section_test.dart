import 'package:architect_engine/data/survey_corridor_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/screens/corridor_section_screen.dart';
import 'package:architect_engine/services/corridor_section_generator.dart';
import 'package:architect_engine/services/longitudinal_profile_generator.dart';
import 'package:architect_engine/services/survey_corridor_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'longitudinal_profile_test.dart' show profile;

ProjectBrief section({Map<String, Object> edits = const {}, String type = 'road', Map<String, int> spaces = const {}}) =>
    profile(edits: {
      'corridor_cad_mode': 'survey_section', 'section_reference': 'BM12 site datum', 'section_chainage': 125.25,
      'section_ground': '-6,100;8,100', 'section_design': '-4,99\n0,101\n6,98', ...edits,
    }, type: type, spaces: spaces);

void main() {
  final gen = CorridorSectionGenerator();

  test('interior intersections split cut from fill and scale does not affect quantities', () {
    expect(surveyCorridorMode.options.map((o) => o.id), contains('survey_section'));
    for (final scale in [1, 5, 10]) {
      final saved = ProjectBrief.fromMap(section(edits: {'section_exaggeration': '$scale'}).toMap())!;
      expect(CorridorSectionGenerator.requested(saved), isTrue);
      expect(LongitudinalProfileGenerator.requested(saved), isFalse);
      expect(SurveyCorridorGenerator.requested(saved), isFalse);
      final result = gen.generate(saved);
      expect(result.issue, isNull);
      expect(result.chainageMm, 125250);
      expect(result.datumMm, 97000);
      expect(result.exaggeration, scale);
      expect(result.cutM2, closeTo(5, 1e-9));
      expect(result.fillM2, closeTo(2, 1e-9));
      expect(result.bands.map((b) => b.crossfallPercent), [50, -50]);
      final cad = result.drawing!;
      final ground = cad.lines.singleWhere((line) => line.layer == 'SECTION_GROUND');
      expect((ground.start.x, ground.start.y, ground.end.x, ground.end.y), (-6000, 3000 * scale, 8000, 3000 * scale));
      final design = cad.lines.where((line) => line.layer == 'SECTION_DESIGN').toList();
      expect((design.first.start.x, design.first.start.y, design.first.end.x, design.first.end.y), (-4000, 2000 * scale, 0, 4000 * scale));
      expect(cad.lines.where((l) => l.layer == 'SECTION_CUT').every((l) => l.start.x < -2000 || l.start.x > 2000), isTrue);
      expect(cad.lines.where((l) => l.layer == 'SECTION_FILL').every((l) => l.start.x > -2000 && l.start.x < 2000), isTrue);
      final dxf = cad.toDxf();
      expect(dxf, contains('X = SIGNED OFFSET MM / Y = (LEVEL - 97.000 M) x $scale IN MM'));
      for (final layer in ['SECTION_CUT', 'SECTION_FILL', 'SECTION_GROUND', 'SECTION_DESIGN', 'SECTION_AXES']) {
        expect(dxf, contains(layer));
      }
    }
  });

  test('merges survey breakpoints, interpolates at design limits and leaves context out of areas', () {
    final result = gen.generate(section(edits: {'section_ground': '-5,0;0,2;5,0', 'section_design': '-4,1;4,1'}));
    expect(result.issue, isNull);
    expect(result.cutM2, closeTo(2.5, 1e-9));
    expect(result.fillM2, closeTo(.9, 1e-9));
    expect(result.bands.single.crossfallPercent, 0);
  });

  test('coincident profiles with different breakpoints have no cut or fill', () {
    final result = gen.generate(section(edits: {'section_ground': '-7,-2;3,1;8,2.5', 'section_design': '-6,-1.7;0,.1;6,1.9'}));
    expect(result.issue, isNull);
    expect((result.cutM2, result.fillM2), (0, 0));
    expect(result.drawing!.lines.where((l) => l.layer == 'SECTION_CUT' || l.layer == 'SECTION_FILL'), isEmpty);
  });

  test('invalid ordering, centreline span and missing coverage block export', () {
    for (final (brief, reason) in [
      (section(type: 'intersection'), 'Select a Road'),
      (section(spaces: {'crossing': 1}), 'separate Space selections'),
      (section(edits: {'section_chainage': -1}), 'Enter a chainage'),
      (section(edits: {'section_design': '-4,0;0,1;0,2;6,0'}), 'increase strictly'),
      (section(edits: {'section_design': '0,0;6,0'}), 'span offset zero'),
      (section(edits: {'section_ground': '-3,0;8,0'}), 'cannot be extrapolated'),
      (section(edits: {'section_ground': '-6,100.0001;8,100'}), 'three decimals'),
      (section(edits: {'section_exaggeration': '3'}), 'available vertical exaggeration'),
    ]) {
      final result = gen.generate(brief);
      expect(result.issue, contains(reason));
      expect(result.drawing, isNull);
    }
  });

  testWidgets('cross-section preview shows areas and hides export for invalid coverage', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CorridorSectionScreen(name: 'Main road', brief: section())));
    expect(find.text('Corridor cross-section CAD'), findsOneWidget);
    expect(find.text('Cut 5.000 m² · Fill 2.000 m²'), findsOneWidget);
    expect(find.text('Share cross-section DXF'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: CorridorSectionScreen(key: const ValueKey('invalid'), name: 'Main road',
      brief: section(edits: {'section_ground': '-3,0;3,0'}))));
    expect(find.textContaining('cannot be extrapolated'), findsOneWidget);
    expect(find.text('Share cross-section DXF'), findsNothing);
  });
}
