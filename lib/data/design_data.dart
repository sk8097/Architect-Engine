import '../models/module_models.dart';

class DesignData {
  static const List<DesignModule> modules = [
    DesignModule(
      id: 1,
      icon: '📐',
      key: 'floor_plan',
      status: 'progress',
    ),
    DesignModule(
      id: 2,
      icon: '🏞️',
      key: 'site_plan',
      status: 'planned',
    ),
    DesignModule(
      id: 3,
      icon: '🏠',
      key: 'elevation',
      status: 'planned',
    ),
    DesignModule(
      id: 4,
      icon: '📉',
      key: 'section',
      status: 'planned',
    ),
    DesignModule(
      id: 5,
      icon: '📦',
      key: 'view_3d',
      status: 'planned',
    ),
    DesignModule(
      id: 6,
      icon: '🛋️',
      key: 'interior',
      status: 'planned',
    ),
    DesignModule(
      id: 7,
      icon: '🌳',
      key: 'landscape',
      status: 'planned',
    ),
    DesignModule(
      id: 8,
      icon: '🏗️',
      key: 'structural',
      status: 'planned',
    ),
    DesignModule(
      id: 9,
      icon: '⚡',
      key: 'electrical',
      status: 'planned',
    ),
    DesignModule(
      id: 10,
      icon: '🚿',
      key: 'plumbing',
      status: 'planned',
    ),
    DesignModule(
      id: 11,
      icon: '📋',
      key: 'coordinated_drawings',
      status: 'planned',
      isFullCard: true,
    ),
  ];

  static final Map<int, Map<String, String>> moduleDetails = {
    1: {
      'name': 'Floor Plan',
      'desc': 'Room layouts & architectural spatial arrangement',
      'full': 'Building ka primary architectural layout, room boundaries, dimensions, wall thickness, and door/window placements.',
    },
    2: {
      'name': 'Site Plan',
      'desc': 'Plot & site zoning and landscape coordinates',
      'full': 'Building ko poore plot aur surroundings mein position karna, setback distance, access roads, and North orientation.',
    },
    3: {
      'name': 'Elevation',
      'desc': 'Exterior views, facade treatments & levels',
      'full': 'Front, rear, and side exterior elevations showing architectural facade styling, sill/lintel heights, and floor levels.',
    },
    4: {
      'name': 'Section',
      'desc': 'Vertical cuts through building structural levels',
      'full': 'Building ke through vertical cut showing slab thickness, foundation depth, staircase headroom, and roof construction.',
    },
    5: {
      'name': '3D View',
      'desc': 'Spatial volumetric 3D representation',
      'full': '3D interactive massing, daylight simulation, and textured exterior/interior walkthrough representations.',
    },
    6: {
      'name': 'Interior',
      'desc': 'Spaces, furniture layouts & finishes',
      'full': 'Room-wise space planning, furniture clearances, false ceiling layouts, flooring materials, and finish schedules.',
    },
    7: {
      'name': 'Landscape',
      'desc': 'Outdoor design, paving & planting layout',
      'full': 'Outdoor hardscape and softscape design, driveway paving, garden zones, drainage channels, and exterior lighting.',
    },
    8: {
      'name': 'Structural',
      'desc': 'Structural engineering & frame coordination',
      'full': 'Column-beam grid layout, footing center lines, slab reinforcement schedules, and engineer design coordination.',
    },
    9: {
      'name': 'Electrical',
      'desc': 'Power conduits, fixtures & circuit loads',
      'full': 'Lighting points, power sockets, switchboard locations, conduit pathways, DB distribution, and connected load schedules.',
    },
    10: {
      'name': 'Plumbing',
      'desc': 'Water supply, drainage & sanitary lines',
      'full': 'Potable cold/hot water distribution, soil & waste drainage slope routes, inspection chambers, and overhead tank sizing.',
    },
    11: {
      'name': 'Coordinated Drawings & Documents',
      'desc': 'Drawing sets, revision control & multi-discipline coordination',
      'full': 'Integrated BIM coordination overlay preventing MEP vs Structural clashes, drawing register tracking, and revision approvals.',
    },
  };
}
