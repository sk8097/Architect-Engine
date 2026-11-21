/// User-supplied high-rise concept requirements. Lengths are integer mm.
class TowerSpace {
  const TowerSpace(this.name, this.width, this.depth, {this.window});
  final String name;
  final int width, depth;
  final int? window;

  Map<String, dynamic> toMap() => {'name': name, 'width': width, 'depth': depth, 'window': window};
  static TowerSpace fromMap(Map<String, dynamic> map) => TowerSpace(
    map['name'] as String, map['width'] as int, map['depth'] as int, window: map['window'] as int?,
  );
  static List<TowerSpace> readList(Object? value) => (value as List<dynamic>)
    .map((item) => fromMap(item as Map<String, dynamic>)).toList(growable: false);
}

/// Inward offsets measured from the corresponding edge of the ground plate.
class TowerPlateInsets {
  const TowerPlateInsets({this.west = 0,this.south = 0,this.east = 0,this.north = 0});
  final int west,south,east,north;
  bool get isZero => west==0 && south==0 && east==0 && north==0;
  Map<String,int> toMap()=>{'west':west,'south':south,'east':east,'north':north};
  static TowerPlateInsets fromMap(Map<String,dynamic> map)=>TowerPlateInsets(west:map['west'] as int,
    south:map['south'] as int,east:map['east'] as int,north:map['north'] as int);
}

class TowerFloorGroup {
  TowerFloorGroup(this.name, this.first, this.last, Iterable<TowerSpace> spaces, {this.insets = const TowerPlateInsets()})
    : spaces = List.unmodifiable(spaces);
  final String name;
  final int first, last;
  final List<TowerSpace> spaces;
  final TowerPlateInsets insets;
  String get range => first == last ? 'Level $first' : 'Levels $first-$last';

  Map<String, dynamic> toMap() => {'name': name, 'first': first, 'last': last,
    'spaces': spaces.map((item) => item.toMap()).toList(), if (!insets.isZero) 'insets': insets.toMap()};
  static TowerFloorGroup fromMap(Map<String, dynamic> map) => TowerFloorGroup(
    map['name'] as String, map['first'] as int, map['last'] as int, TowerSpace.readList(map['spaces']),
    insets: map['insets'] == null ? const TowerPlateInsets() : TowerPlateInsets.fromMap(map['insets'] as Map<String,dynamic>),
  );
}

class TowerBrief {
  TowerBrief({required this.floors, required this.plotWidth, required this.plotDepth,
    required this.plateWidth, required this.plateDepth, required this.westOffset, required this.southOffset,
    required this.frontage, required this.wall, required this.corridor, required this.door,
    required this.basis, required Iterable<TowerSpace> stairs, required Iterable<TowerSpace> lifts,
    required Iterable<TowerSpace> shafts, required Iterable<TowerFloorGroup> groups})
    : stairs = List.unmodifiable(stairs), lifts = List.unmodifiable(lifts), shafts = List.unmodifiable(shafts),
      groups = List.unmodifiable(groups);

  final int floors, plotWidth, plotDepth, plateWidth, plateDepth, westOffset, southOffset;
  final int wall, corridor, door;
  final String frontage, basis;
  final List<TowerSpace> stairs, lifts, shafts;
  final List<TowerFloorGroup> groups;

  Map<String, dynamic> toMap() => {'version': 1, 'floors': floors, 'plotWidth': plotWidth,
    'plotDepth': plotDepth, 'plateWidth': plateWidth, 'plateDepth': plateDepth, 'westOffset': westOffset,
    'southOffset': southOffset, 'frontage': frontage, 'wall': wall, 'corridor': corridor, 'door': door,
    'basis': basis, 'stairs': stairs.map((item) => item.toMap()).toList(),
    'lifts': lifts.map((item) => item.toMap()).toList(), 'shafts': shafts.map((item) => item.toMap()).toList(),
    'groups': groups.map((item) => item.toMap()).toList()};

  static TowerBrief? fromMap(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) return null;
    try {
      int n(String key) => value[key] as int;
      String s(String key) => value[key] as String;
      return TowerBrief(floors: n('floors'), plotWidth: n('plotWidth'), plotDepth: n('plotDepth'),
        plateWidth: n('plateWidth'), plateDepth: n('plateDepth'), westOffset: n('westOffset'), southOffset: n('southOffset'),
        frontage: s('frontage'), wall: n('wall'), corridor: n('corridor'), door: n('door'), basis: s('basis'),
        stairs: TowerSpace.readList(value['stairs']), lifts: TowerSpace.readList(value['lifts']),
        shafts: TowerSpace.readList(value['shafts']), groups: (value['groups'] as List<dynamic>)
          .map((item) => TowerFloorGroup.fromMap(item as Map<String, dynamic>)));
    } on TypeError {
      return null;
    }
  }
}
