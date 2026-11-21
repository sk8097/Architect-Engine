import 'project_requirements.dart';
import 'space_planning.dart';

bool culvertCadEligible(String? category, String? group, String? type) =>
    category == 'infrastructure' && group == 'water' && type == 'culvert';

final culvertCadMode = planningChoice('culvert_cad_mode', 'Culvert drawing', {
  'survey_crossing': 'Surveyed road crossing: culvert plan and barrel profile',
}, required: false);

RequirementField _measure(String key, String label, String unit, num min, num max) =>
    RequirementField(key, label, kind: RequirementKind.decimal, unit: unit, min: min, max: max, required: true);

final culvertCadFields = <RequirementField>[
  const RequirementField('cv_grid', 'Projected survey grid / CRS in metres', required: true),
  const RequirementField('cv_reference', 'Survey source and common elevation datum', required: true),
  const RequirementField('cv_ends', 'Inlet then outlet: Easting,Northing,surface,invert (m); separate rows by ; or newline', required: true),
  const RequirementField('cv_surface', 'Intermediate surface points: chainage,level (m) from inlet; separate rows by ; or newline'),
  _measure('cv_road_station', 'Road centreline intersection chainage from inlet', 'm', .001, 2000),
  _measure('cv_road_bearing', 'Grid bearing of the straight road axis, clockwise from grid north', '°', 0, 360),
  _measure('cv_road_width', 'Width of road area requiring cover, perpendicular to road', 'm', .001, 300),
  _measure('cv_barrel_width', 'Outside barrel width in plan', 'm', .001, 20),
  _measure('cv_crown', 'Vertical difference from invert to outside barrel crown', 'm', .001, 20),
  _measure('cv_cover', 'Required minimum cover below the road surface', 'm', 0, 100),
  _measure('cv_fall', 'Required minimum downstream fall', '%', 0, 100),
  planningChoice('cv_scale', 'Profile vertical exaggeration', {'1': '1× true scale', '5': '5× vertical', '10': '10× vertical'}, required: false),
];
