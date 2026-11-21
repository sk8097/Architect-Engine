import '../data/greenhouse_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;

class GreenhouseCadResult {
  const GreenhouseCadResult(this.plan, this.issue, {this.zones = const [], this.benchAreaMm2 = 0});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
  final int benchAreaMm2;
}

/// One greenhouse with two split banks, each connected to the front, rear and
/// middle crosswalk. Optional schematic only, not a piping design.
class GreenhouseCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == 'greenhouse_benches';

  GreenhouseCadResult generate(ProjectBrief brief, {required double widthFt,
    required double depthFt, required String facing}) {
    GreenhouseCadResult stop(String issue) => GreenhouseCadResult(null, issue);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !greenhouseCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Greenhouse Farm and save a brief with the current measured fields.');
    }
    final a = snap.answers;
    bool positive(String key) => a[key] is num && (a[key] as num) > 0;
    if (brief.floorCount != 1 || (a['building_count'] ?? 1) != 1 || positive('basements') ||
        positive('mezzanines') || !const {null, 'production_site'}.contains(sel.configurationId)) {
      return stop('Use one ground-floor production greenhouse, not a residence, compound or multi-building farm.');
    }
    if (!const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        const {'existing', 'brownfield', 'partial_demolition'}.contains(a['build_status']) ||
        const {'existing', 'partial', 'renovation', 'demolish'}.contains(a['construction_status'])) {
      return stop('This template draws a new concept, not a surveyed greenhouse retrofit or approval drawing.');
    }
    if (sel.spaceQuantities.isNotEmpty || !const {null, ProjectParking.none}.contains(brief.parking) ||
        a['parking_sqft'] != null || a['terrace_needed'] == 'yes') {
      return stop('This output draws the measured greenhouse directly. Leave separate Space selections empty; parking and terraces are not drawn.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId) ||
        !const {'North', 'East', 'South', 'West'}.contains(facing)) {
      return stop('Use a measured rectangular or square plot and a cardinal entrance frontage.');
    }
    int? mm(Object? raw, {bool zero = false}) {
      if (raw is! num || !raw.isFinite || raw < 0 || raw > 300) return null;
      final n = (raw * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final plotW = mm(widthFt * .3048), plotD = mm(depthFt * .3048);
    final w = mm(a['cad_plate_width']), d = mm(a['cad_plate_depth']);
    final x = mm(a['cad_offset_left'], zero: true), y = mm(a['cad_offset_front'], zero: true), t = mm(a['cad_wall']);
    if (plotW == null || plotD == null || w == null || d == null || x == null || y == null || t == null ||
        (sel.plotShapeId == 'square' && plotW != plotD)) {
      return stop('Enter valid plot and greenhouse envelope sizes, offsets and enclosure thickness.');
    }
    for (final (side, clear) in [('left', x), ('right', plotW - x - w), ('front', y), ('rear', plotD - y - d)]) {
      final raw = a['${side}_setback'], setback = raw == null ? 0 : mm(raw, zero: true);
      if (setback == null || clear < setback) return stop('The greenhouse conflicts with the plot or the supplied $side setback.');
    }
    final fsi = a['fsi_limit'], coverage = a['coverage_limit'];
    if (fsi is num && w * d > plotW * plotD * fsi) return stop('The greenhouse exceeds the supplied FAR/FSI allowance.');
    if (coverage is num && w * d > plotW * plotD * coverage / 100) return stop('The greenhouse exceeds the supplied site coverage.');

    final n = a['gh_pair_rows'], bw = mm(a['gh_bench_width']), bl = mm(a['gh_bench_length']), gap = mm(a['gh_bench_aisle']);
    final main = mm(a['gh_main_aisle']), cross = mm(a['gh_cross_aisle']), door = mm(a['cad_door']);
    final front = mm(a['gh_front_clear']), rear = mm(a['gh_rear_clear']);
    if (n is! int || n < 1 || n > 16 || bw == null || bl == null || gap == null || main == null ||
        cross == null || door == null || front == null || rear == null) {
      return stop('Enter 1–16 bench rows per bank and all measured bench, aisle, end clearance and door widths.');
    }
    final irrigation = a['gh_irrigation'];
    if (!const {null, 'none', 'layout_only'}.contains(irrigation)) return stop('Choose a supported irrigation drawing option.');
    if (door <= t || door > main || y <= 0) return stop('Align the door within the centre aisle, with a clear approach in front of the greenhouse.');
    final iw = w - 2 * t, id = d - 2 * t;
    final bank = n * (bw + gap), needW = 2 * bank + main;
    if (iw < needW) {
      return stop('Both bench banks, side aisles and the main aisle require ${(needW / 1000).toStringAsFixed(3)} m clear width.');
    }
    // A door must be able to swing fully inside the clear front headland.
    final frontMin = front > door ? front : door;
    final needD = frontMin + rear + 2 * bl + cross;
    if (id < needD) {
      return stop('The front door swing, two bench sections, cross-aisle and end clearances require ${(needD / 1000).toStringAsFixed(3)} m clear depth.');
    }
    final frontEnd = frontMin + (id - needD) ~/ 2, crossStart = frontEnd + bl;
    final crossEnd = crossStart + cross, rearStart = crossEnd + bl;
    final bankStart = (iw - needW) ~/ 2, mainLeft = bankStart + bank, mainRight = mainLeft + main;
    final dx = mainLeft + (main - door) ~/ 2, mainX = mainLeft + main ~/ 2;
    final rotated = facing == 'East' || facing == 'West';
    PlanRect orient(PlanRect b) => switch (facing) {
      'North' => PlanRect(plotW - b.right, plotD - b.top, plotW - b.left, plotD - b.bottom),
      'East' => PlanRect(plotD - b.top, b.left, plotD - b.bottom, b.right),
      'West' => PlanRect(b.bottom, plotW - b.right, b.top, plotW - b.left),
      _ => b,
    };
    PlanRect rect(int l, int b, int r, int top) => orient(PlanRect(x + t + l, y + t + b, x + t + r, y + t + top));
    final aisles = <MeasuredZone>[], benches = <MeasuredZone>[], lines = <PlanMarking>[];
    void mark(String layer, int x1, int y1, int x2, int y2) {
      final p = rect(x1, y1, x1, y1), q = rect(x2, y2, x2, y2);
      lines.add(PlanMarking(layer, p.left, p.bottom, q.left, q.bottom));
    }
    const working = 'GREENHOUSE_HEADLAND', path = 'GREENHOUSE_AISLES', fixture = 'GREENHOUSE_BENCHES';
    const trunk = 'GREENHOUSE_IRR_HEADER', lateral = 'GREENHOUSE_IRR_LATERALS';
    const grow = 'greenhouse_growing';
    final mid = crossStart + cross ~/ 2;
    final headerNodes = <int>[];
    aisles.addAll([
      MeasuredZone('gh_entry', 'Front approach', rect(mainLeft, -y - t, mainRight, -t), 'GREENHOUSE_APPROACH'),
      MeasuredZone('gh_front', 'Front clear working space', rect(0, 0, iw, frontEnd), working),
      MeasuredZone('gh_middle', 'Cross-aisle', rect(0, crossStart, iw, crossEnd), working),
      MeasuredZone('gh_rear', 'Rear clear working space', rect(0, rearStart, iw, id), working),
    ]);
    for (final (section, start, end) in [('front', frontEnd, crossStart), ('rear', crossEnd, rearStart)]) {
      aisles.add(MeasuredZone('gh_${section}_main', 'Main aisle', rect(mainLeft, start, mainRight, end), path));
      for (final (side, left) in [('left', bankStart), ('right', mainRight)]) {
        for (var i = 0; i < n; i++) {
          // Outer aisle plus inter-row aisles; excess enclosure width is
          // added only to the exterior aisles, leaving the main aisle exact.
          final run = left + i * (bw + gap);
          final bx = side == 'left' ? run + gap : run;
          final aisleL = side == 'left' ? (i == 0 ? 0 : run) : run + bw;
          final aisleR = side == 'left' ? run + gap : (i == n - 1 ? iw : run + bw + gap);
          final key = 'gh_${section}_${side}_$i';
          benches.add(MeasuredZone('${key}_bench', 'Growing bench', rect(bx, start, bx + bw, end), fixture));
          aisles.add(MeasuredZone('${key}_aisle', 'Bench aisle', rect(aisleL, start, aisleR, end), path));
          if (irrigation == 'layout_only') {
            final takeoff = bx + bw ~/ 2;
            if (section == 'front') headerNodes.add(takeoff);
            mark(lateral, takeoff, section == 'front' ? start : mid, takeoff, section == 'front' ? mid : end);
          }
        }
      }
    }
    if (irrigation == 'layout_only') {
      // Split the header at every take-off to make the schematic network
      // explicitly connected in the editable linework.
      headerNodes.add(mainX);
      headerNodes.sort();
      mark(trunk, mainX, 0, mainX, mid);
      for (var i = 1; i < headerNodes.length; i++) {
        mark(trunk, headerNodes[i - 1], mid, headerNodes[i], mid);
      }
    }
    final plan = AutomaticFloorPlan(plot: PlanRect(0, 0, rotated ? plotD : plotW, rotated ? plotW : plotD),
      footprint: orient(PlanRect(x, y, x + w, y + d)), facing: facing, sheetTitle: 'GREENHOUSE / GROWING BENCHES & ACCESS',
      rooms: [PlanRoom(grow, 'Enclosed growing bay', rect(0, 0, iw, id))], walls: [
        rect(-t, -t, 0, id + t), rect(iw, -t, iw + t, id + t), rect(0, id, iw, id + t),
        rect(0, -t, dx, 0), rect(dx + door, -t, iw, 0),
      ], openings: [PlanOpening(PlanOpeningKind.door, rect(dx, -t, dx + door, 0), AutomaticFloorPlan.entry, grow)],
      markings: lines);
    final issue = validatePlanGeometry(plan);
    if (issue != null) return stop('Greenhouse envelope failed geometry validation: $issue');
    return GreenhouseCadResult(plan, null, zones: List.unmodifiable([...aisles, ...benches]), benchAreaMm2: 4 * n * bw * bl);
  }
}
