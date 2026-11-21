import 'project_requirements.dart';
import 'space_planning.dart';

final corridorEarthworkFields = <RequirementField>[
  const RequirementField('ew_reference', 'Cross-section survey source / common benchmark datum', required: true),
  const RequirementField('ew_ground', 'Surveyed chainage,offset,level (m) per line or separated by ;', required: true),
  const RequirementField('ew_design', 'Proposed chainage,offset,level (m) per line or separated by ;', required: true),
  planningChoice('ew_exaggeration', 'Vertical exaggeration for all section drawings', {
    '1': '1× true scale', '5': '5× vertical', '10': '10× vertical',
  }, required: false),
];
