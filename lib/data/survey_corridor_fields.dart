import 'cycle_crossing_cad_fields.dart';
import 'project_requirements.dart';
import 'refuge_crossing_cad_fields.dart';
import 'space_planning.dart';

const surveyCorridorTypes = {'road','street','footpath','cycle_track'};

const surveyCorridorCadModes = {'survey_polyline','survey_circular'};

final surveyCorridorMode = surveyCorridorModeField();

RequirementField surveyCorridorModeField({bool includeCycleCrossings = false, bool includeRefugeCrossing = false}) => planningChoice('corridor_cad_mode', 'Corridor drawing', {
  'straight': 'Straight corridor zoning', 'survey_polyline': 'Survey points: multi-segment corridor CAD',
  'survey_circular': 'Tangent survey with measured circular bends',
  'survey_profile': 'Longitudinal profile: survey levels and proposed grades',
  'survey_section': 'Cross-section: surveyed ground and proposed surface',
  'survey_earthwork': 'Earthwork takeoff: multi-station surveyed cross-sections',
  if (includeRefugeCrossing) refugeCrossingMode: 'Surveyed staggered pedestrian refuge',
  if (includeCycleCrossings) cycleCrossingMode: 'Separated cycle track: surveyed driveway crossings',
}, required: false);

const surveyCorridorFields = <RequirementField>[
  RequirementField('corridor_grid', 'Survey grid / projected CRS reference', required: true),
  RequirementField('corridor_points', 'Ordered Easting,Northing in m (one pair per line or separated by ;)', required: true),
  RequirementField('corridor_start_station', 'Starting chainage (m)', kind: RequirementKind.decimal,
    unit: 'm', min: 0, max: 1000000, required: true),
];

const surveyCorridorBands = RequirementField('corridor_bands',
  'Bands from left to right looking forward: Label:width in m; Label:width in m');

const surveyCurveRadii = RequirementField('corridor_curve_radii',
  'Bend radii in m for intermediate points in order (separate with ;)', required:true);
