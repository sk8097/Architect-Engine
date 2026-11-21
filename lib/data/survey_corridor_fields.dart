import 'project_requirements.dart';
import 'space_planning.dart';

const surveyCorridorTypes = {'road','street','footpath','cycle_track'};

final surveyCorridorMode = planningChoice('corridor_cad_mode', 'Corridor drawing', {
  'straight': 'Straight corridor zoning', 'survey_polyline': 'Survey points: multi-segment corridor CAD',
}, required: false);

const surveyCorridorFields = <RequirementField>[
  RequirementField('corridor_grid', 'Survey grid / projected CRS reference', required: true),
  RequirementField('corridor_points', 'Ordered Easting,Northing in m (one pair per line or separated by ;)', required: true),
  RequirementField('corridor_start_station', 'Starting chainage (m)', kind: RequirementKind.decimal,
    unit: 'm', min: 0, max: 1000000, required: true),
];

const surveyCorridorBands = RequirementField('corridor_bands',
  'Bands from left to right looking forward: Label:width in m; Label:width in m');
