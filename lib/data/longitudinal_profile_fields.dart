import 'project_requirements.dart';
import 'space_planning.dart';

final longitudinalProfileFields = <RequirementField>[
  const RequirementField('profile_reference', 'Level survey source / benchmark datum reference', required: true),
  const RequirementField('profile_ground', 'Surveyed chainage,level in m; one pair per line or separated by ;', required: true),
  const RequirementField('profile_grade', 'Proposed chainage,level,curve length in m; one triple per line or separated by ;', required: true),
  planningChoice('profile_exaggeration', 'Vertical exaggeration in preview and DXF', {
    '1': '1× true scale', '5': '5× vertical', '10': '10× vertical',
  }, required: false),
];
