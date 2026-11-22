import 'package:architect_engine/data/typology_bay_cad_fields.dart';
import 'package:architect_engine/models/project_brief.dart';
import 'package:architect_engine/models/project_requirements.dart';
import 'package:architect_engine/services/typology_bay_cad_generator.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectBrief _brief(String category, String group, String type, Map<String, String> answers) =>
    ProjectBrief(
      categoryId: category,
      groupId: group,
      typeId: type,
      configurationId: 'standard',
      requirements: ProjectRequirements(answers: answers),
    );

void main() {
  test('TypologyBayCadGenerator produces valid plan, section, and DXF across categories', () {
    final answers = {
      'cad_output': typologyBayMode,
      'tb_site_w': '30',
      'tb_site_d': '40',
      'tb_setback_front': '6',
      'tb_setback_side': '3',
      'tb_setback_rear': '4',
      'tb_bays_x': '4',
      'tb_bays_y': '3',
      'tb_bay_w': '5',
      'tb_bay_d': '6',
      'tb_corridor_w': '2.4',
      'tb_clear_h': '3.6',
      'tb_storeys': '2',
    };

    for (final tuple in const [
      ('residential', 'houses', 'courtyard_house'),
      ('commercial', 'office', 'headquarters'),
      ('industrial', 'manufacturing', 'heavy_manufacturing'),
      ('rural', 'agro_processing', 'rice_mill'),
      ('special', 'heritage', 'heritage_residence'),
    ]) {
      final brief = _brief(tuple.$1, tuple.$2, tuple.$3, answers);
      expect(TypologyBayCadGenerator.requested(brief), isTrue);
      final res = TypologyBayCadGenerator().generate(brief);
      expect(res.issue, isNull);
      expect(res.plan, isNotNull);
      expect(res.section, isNotNull);
      expect(res.footprintArea, closeTo(20.0 * 20.4, 1e-6));
      expect(res.grossFloorArea, closeTo(20.0 * 20.4 * 2, 1e-6));
      expect(res.circulationArea, closeTo(20.0 * 2.4 * 2, 1e-6));
      expect(res.netUsableArea, closeTo(res.grossFloorArea - res.circulationArea, 1e-6));
      expect(res.plan!.toDxf(), contains('ENTITIES'));
      expect(res.section!.toDxf(), contains('ENTITIES'));
    }
  });

  test('TypologyBayCadGenerator rejects footprint exceeding site after setbacks', () {
    final brief = _brief('rural', 'agro_processing', 'silo_complex', {
      'cad_output': typologyBayMode,
      'tb_site_w': '15',
      'tb_site_d': '20',
      'tb_setback_front': '3',
      'tb_setback_side': '3',
      'tb_setback_rear': '3',
      'tb_bays_x': '3',
      'tb_bays_y': '2',
      'tb_bay_w': '4',
      'tb_bay_d': '4',
      'tb_corridor_w': '2',
      'tb_clear_h': '3.5',
      'tb_storeys': '1',
    });
    final res = TypologyBayCadGenerator().generate(brief);
    expect(res.issue, isNotNull);
    expect(res.plan, isNull);
    expect(res.section, isNull);
  });
}
