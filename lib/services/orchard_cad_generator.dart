import 'dart:math' as math;

import '../data/orchard_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class OrchardTree {
  const OrchardTree(this.row, this.index, this.point);
  final int row, index;
  final CadPoint point;
  String get id => 'R${row.toString().padLeft(2, '0')}-T${index.toString().padLeft(2, '0')}';
}

class OrchardCadResult {
  const OrchardCadResult({this.drawing, this.issue, this.trees = const []});
  final FloorPlanCad? drawing;
  final String? issue;
  final List<OrchardTree> trees;

  String? toCsv() {
    if (drawing == null) return null;
    String m(num n) => (n / 1000).toStringAsFixed(4); // Odd diameters give half-mm centre coordinates.
    return ['tree_id,row,tree_in_row,east_from_plot_sw_m,north_from_plot_sw_m',
      for (final tree in trees) '${tree.id},${tree.row},${tree.index},${m(tree.point.x)},${m(tree.point.y)}', ''].join('\r\n');
  }
}

/// Uniform planting grid and a continuous access loop sized to the supplied
/// clear dimensions. Tree/set-out coordinates stay in a local cardinal grid.
class OrchardCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'orchard_measured_rows';

  OrchardCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt}) {
    OrchardCadResult stop(String issue) => OrchardCadResult(issue: issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !orchardCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Orchard Estate or Plantation Estate and save the current planting brief.');
    }
    if (!const {null, 'production_site'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use a new Production Site without structures, parking or separate Space selections.');
    }
    if (!const {'square', 'rectangular'}.contains(sel.plotShapeId)) return stop('Use a measured square or rectangular plot aligned to the cardinal axes.');
    final a = snap.answers, axis = snap.answers['orc_axis'];
    int? mm(Object? v, {bool zero = false, double max = 2000}) {
      if (v is! num || !v.isFinite || v < 0 || v > max) return null;
      final n = (v * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final w = mm(widthFt * .3048), d = mm(depthFt * .3048);
    final west = mm(a['orc_west'], zero: true), south = mm(a['orc_south'], zero: true);
    final rowPitch = mm(a['orc_row_pitch'], max: 200), treePitch = mm(a['orc_tree_pitch'], max: 200);
    final canopy = mm(a['orc_canopy'], max: 100), head = mm(a['orc_headland'], max: 100), side = mm(a['orc_side_lane'], max: 100);
    final rows = a['orc_rows'], treesPerRow = a['orc_trees'];
    if (w == null || d == null || west == null || south == null || (axis != 'ns' && axis != 'ew') ||
        rows is! int || treesPerRow is! int || rows < 1 || rows > 120 || treesPerRow < 1 || treesPerRow > 120 ||
        rowPitch == null || treePitch == null || canopy == null || head == null || side == null || (sel.plotShapeId == 'square' && w != d)) {
      return stop('Enter measured plot dimensions, row axis, tree counts, spacing, canopy diameter and clear access widths.');
    }
    if (rows * treesPerRow > 3000) return stop('Limit each drawing to 3,000 trees. Split larger plantings into blocks.');
    if ((rows > 1 && rowPitch < canopy) || (treesPerRow > 1 && treePitch < canopy)) {
      return stop('The entered tree or row spacing overlaps the reserved mature canopies.');
    }
    final across = 2 * side + canopy + (rows - 1) * rowPitch;
    final along = 2 * head + canopy + (treesPerRow - 1) * treePitch;
    final ns = axis == 'ns', blockW = ns ? across : along, blockD = ns ? along : across;
    for (final (key, edge, clear) in [
      ('left_setback', 'west', west), ('right_setback', 'east', w - west - blockW),
      ('front_setback', 'south', south), ('rear_setback', 'north', d - south - blockD),
    ]) {
      final raw = a[key], setback = raw == null ? 0 : mm(raw, zero: true);
      if (setback == null || clear < setback) return stop('The planting block and access loop conflict with the $edge plot edge or supplied setback.');
    }
    CadPoint p(num u, num v) => ns ? CadPoint(west + u, south + v) : CadPoint(west + v, south + across - u);
    PlanRect orientedBox(int u, int v, int uu, int vv) => ns ? PlanRect(west+u,south+v,west+uu,south+vv)
        : PlanRect(west+v,south+across-uu,west+vv,south+across-u);
    final access = [
      ('ORCHARD_HEADLAND', orientedBox(0,0,across,head)), ('ORCHARD_HEADLAND', orientedBox(0,along-head,across,along)),
      ('ORCHARD_LANE', orientedBox(0,head,side,along-head)), ('ORCHARD_LANE', orientedBox(across-side,head,across,along-head)),
    ];
    final excludes = <String, PlanRect>{};
    final raw = a['orc_exclusions'];
    if (raw != null && raw is! String) return stop('Use ID,west offset,south offset,width,depth for exclusions.');
    if (raw is String && raw.trim().isNotEmpty) {
      if (raw.length > 6000) return stop('Limit each planting block to 40 exclusions.');
      for (final row in raw.split(RegExp(r'[;\r\n]+')).where((r) => r.trim().isNotEmpty)) {
        if (excludes.length == 40) return stop('Limit each planting block to 40 exclusions.');
        final data = row.split(',').map((v) => v.trim()).toList();
        if (data.length != 5 || !RegExp(r'^[A-Za-z0-9_-]{1,24}$').hasMatch(data.first) || excludes.containsKey(data.first)) {
          return stop('Each exclusion needs a unique ID plus west offset, south offset, width and depth.');
        }
        final pattern = RegExp(r'^[+]?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
        final dims = data.skip(1).map((v) => pattern.hasMatch(v) ? mm(double.tryParse(v),zero: true) : null).toList();
        if (dims.contains(null) || dims[2] == 0 || dims[3] == 0) return stop('Exclusion ${data.first} needs offsets and positive dimensions in metres to three decimals.');
        final x = dims[0]!, y = dims[1]!;
        final box = PlanRect(x, y, x + dims[2]!, y + dims[3]!);
        if (box.right > w || box.top > d) return stop('Exclusion ${data.first} is outside the plot.');
        if (access.any((zone) => zone.$2.overlaps(box))) return stop('Exclusion ${data.first} overlaps a clear headland or side access lane.');
        excludes[data.first] = box;
      }
    }
    final radius = canopy / 2, trees = <OrchardTree>[];
    for (var r = 0; r < rows; r++) {
      for (var j = 0; j < treesPerRow; j++) {
        final q = p(side + radius + r * rowPitch, head + radius + j * treePitch);
        final tree = OrchardTree(r+1, j+1, q);
        for (final item in excludes.entries) {
          final b = item.value, dx = q.x - q.x.clamp(b.left, b.right), dy = q.y - q.y.clamp(b.bottom, b.top);
          if (dx*dx + dy*dy < radius*radius) return stop('Reserved canopy for ${tree.id} overlaps exclusion ${item.key}.');
        }
        trees.add(tree);
      }
    }

    final lines = <CadLine>[], arcs = <CadArc>[], labels = <CadLabel>[];
    void line(String layer, num x, num y, num r, num t) => lines.add(CadLine(layer, CadPoint(x,y), CadPoint(r,t)));
    void box(String layer, PlanRect b) {
      line(layer,b.left,b.bottom,b.right,b.bottom); line(layer,b.right,b.bottom,b.right,b.top);
      line(layer,b.right,b.top,b.left,b.top); line(layer,b.left,b.top,b.left,b.bottom);
    }
    box('ORCHARD_PLOT', PlanRect(0,0,w,d));
    for (final (layer, bounds) in access) { box(layer, bounds); }
    final text = (math.max(w,d)/86).clamp(50,12000).toDouble();
    for (final item in excludes.entries) {
      box('ORCHARD_EXCLUSION', item.value);
      final b = item.value;
      labels.add(CadLabel('ORCHARD_EXCLUSION', CadPoint((b.left+b.right)/2,(b.bottom+b.top)/2), item.key,text*.7));
    }
    final tick = radius * .18;
    for (final tree in trees) {
      final q = tree.point;
      arcs.addAll([CadArc('ORCHARD_CANOPY',q,radius,0,180), CadArc('ORCHARD_CANOPY',q,radius,180,0)]);
      line('ORCHARD_CENTRE',q.x-tick,q.y,q.x+tick,q.y);
      line('ORCHARD_CENTRE',q.x,q.y-tick,q.x,q.y+tick);
      if (tree.index == 1) labels.add(CadLabel('ORCHARD_CENTRE', p(side+radius+(tree.row-1)*rowPitch,head/2),
        'R${tree.row.toString().padLeft(2,'0')}', math.min(text*.75,rowPitch/5)));
    }
    final ax = w + text * 2;
    line('ANNOTATIONS',ax,d-text*2,ax,d);
    line('ANNOTATIONS',ax-text*.4,d-text*.7,ax,d);
    line('ANNOTATIONS',ax+text*.4,d-text*.7,ax,d);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(ax,d+text),'N',text*.7),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*4.5),'MEASURED ORCHARD PLANTING BLOCK / CONCEPT',text),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*3.1),'$rows ROWS x $treesPerRow TREES / ${trees.length} TOTAL / ${ns ? 'N-S' : 'E-W'}',text*.72),
      CadLabel('ANNOTATIONS',CadPoint(w/2,d+text*1.8),'LOCAL MM / SOUTHWEST PLOT CORNER = 0,0',text*.68),
    ]);
    final bounds = PlanRect(math.min(-text*2,w/2-text*23).floor(),(-text*2).floor(),
      math.max(ax+text*3,w/2+text*23).ceil(),(d+text*6).ceil());
    return OrchardCadResult(drawing: FloorPlanCad.fromEntities(bounds: bounds, lines: lines, arcs: arcs, labels: labels),
      trees: List.unmodifiable(trees));
  }
}
