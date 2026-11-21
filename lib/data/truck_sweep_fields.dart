import 'project_requirements.dart';
import 'space_planning.dart';
import 'warehouse_cad_fields.dart';

bool truckSweepEligible(String? category, String? group, String? type) =>
    category == 'industrial' && group == 'logistics' && warehouseLoadingTypes.contains(type);

RequirementField _metres(String id, String label, {double min = .001}) =>
    RequirementField(id, label, kind: RequirementKind.decimal, unit: 'm', min: min, max: 300, required: true);

final truckSweepFields = <RequirementField>[
  _metres('ts_width', 'Clear paved apron width along frontage'),
  _metres('ts_depth', 'Apron depth from plot frontage to dock face'),
  _metres('ts_offset', 'Apron left edge offset from plot left', min: 0),
  _metres('ts_dock_x', 'Dock centre measured from apron left'),
  _metres('ts_dock_width', 'Clear dock bay width'),
  _metres('ts_radius', 'Measured rear-axle centre turning radius'),
  _metres('ts_wheelbase', 'Rigid vehicle wheelbase'),
  _metres('ts_front', 'Front overhang beyond front axle', min: 0),
  _metres('ts_rear', 'Rear overhang behind rear axle'),
  _metres('ts_body_width', 'Maximum body width including mirrors'),
  _metres('ts_buffer', 'Clearance buffer on each vehicle side and end', min: 0),
  _metres('ts_lead', 'Straight reverse distance before turn', min: 0),
  _metres('ts_reverse', 'Straight reverse distance after turn'),
  _metres('ts_stop_gap', 'Rear bumper gap from dock face at stop'),
  planningChoice('ts_approach_side', 'Approach side looking from frontage towards dock', {'right': 'From right', 'left': 'From left'}),
];

const truckSweepObstacles = RequirementField('ts_obstacles',
  'Fixed apron obstacles: ID,left,front,width,depth (m), from apron left/front; separate with ; or newline');
