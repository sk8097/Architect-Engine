import 'project_requirements.dart';
import 'space_planning.dart';

final corridorSectionFields = <RequirementField>[
  const RequirementField('section_reference', 'Cross-section survey source / benchmark datum', required: true),
  const RequirementField('section_chainage', 'Chainage of this cross-section', kind: RequirementKind.decimal,
    unit: 'm', min: 0, max: 1000000, required: true),
  const RequirementField('section_ground', 'Surveyed offset,level in m; one pair per line or separated by ;', required: true),
  const RequirementField('section_design', 'Proposed offset,level in m; one pair per line or separated by ;', required: true),
  planningChoice('section_exaggeration', 'Vertical exaggeration in preview and DXF', {
    '1': '1× true scale', '5': '5× vertical', '10': '10× vertical',
  }, required: false),
];
