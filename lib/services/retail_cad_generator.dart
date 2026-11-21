import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/retail_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;

class RetailCadResult {
  const RetailCadResult(this.plan, this.zones, this.issue);
  final AutomaticFloorPlan? plan;
  final List<MeasuredZone> zones;
  final String? issue;
}

/// Measured single-shop concept: connected, clear aisle network and a stock
/// partition. Not a capacity, retail licensing or emergency egress analysis.
class RetailCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'retail_fixtures';

  RetailCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    RetailCadResult stop(String msg) => RetailCadResult(null, const [], msg);
    final selection = brief.taxonomy, snapshot = brief.requirements;
    if (selection == null || snapshot == null || selection.version != projectTaxonomyVersion || snapshot.version != requirementsSchemaVersion) {
      return stop('Save a retail brief with the current measured requirements.');
    }
    if (selection.categoryId != 'commercial' || selection.subcategoryId != 'retail' || !retailFixtureTypes.contains(selection.typeId)) {
      return stop('This fixture layout is for a listed single retail shop, not a mall, food court or multi-tenant plan.');
    }
    final data = snapshot.answers;
    if (brief.floorCount != 1 || data['shop_count'] != 1 || (data['building_count'] as num? ?? 1) != 1 ||
        (data['basements'] as num? ?? 0) > 0 || (data['mezzanines'] as num? ?? 0) > 0 ||
        const {'multiple','mall'}.contains(data['retail_form'])) {
      return stop('The measured display template needs one standalone ground-floor shop with no basement or mezzanine.');
    }
    if ((selection.actionId != null && !const {'new_design','concept_design','feasibility'}.contains(selection.actionId)) ||
        const {'existing','brownfield','partial_demolition'}.contains(data['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(data['construction_status'])) {
      return stop('Existing shop fit-outs and construction requests need a surveyed layout. This generator is for a new concept.');
    }
    if ((brief.parking != null && brief.parking != ProjectParking.none) || data['terrace_needed'] == 'yes' || selection.spaceQuantities.isNotEmpty) {
      return stop('This fixture plan draws sales, checkout and stock only. Extra rooms, parking or terrace are not silently dropped; use another drawing type for those requests.');
    }
    if (!const {'rectangular','square'}.contains(selection.plotShapeId) || !const {'North','South','East','West'}.contains(facing)) {
      return stop('Use a measured rectangular or square site and a cardinal entrance side.');
    }
    int? mm(Object? value, {bool zero = false}) {
      if (value is! num || !value.isFinite || value < 0 || value > 300) return null;
      final n = (value * 1000).round();
      return n > 0 || zero ? n : null;
    }
    final plotW = mm(widthFt * .3048), plotD = mm(depthFt * .3048);
    final x = mm(data['cad_offset_left'], zero: true), y = mm(data['cad_offset_front'], zero: true);
    final width = mm(data['cad_plate_width']), depth = mm(data['cad_plate_depth']), t = mm(data['cad_wall']);
    if (plotW == null || plotD == null || x == null || y == null || width == null || depth == null || t == null ||
        (selection.plotShapeId == 'square' && plotW != plotD)) {
      return stop('Enter valid plot and shell dimensions, offsets and wall thickness.');
    }
    final targetFrontage = data['frontage'];
    if (targetFrontage is num && width / 1000 < targetFrontage - .001) return stop('The shell is narrower than the requested shop frontage.');
    final r = x + width, top = y + depth;
    final insets = <String,int>{};
    for (final side in ['left','right','front','rear']) {
      final raw = data['${side}_setback'];
      final inset = raw == null ? 0 : mm(raw, zero: true);
      if (inset == null) return stop('Invalid $side setback.');
      insets[side] = inset;
    }
    if (x < insets['left']! || y < insets['front']! || r > plotW - insets['right']! || top > plotD - insets['rear']!) {
      return stop('The proposed shop shell exceeds the measured plot or supplied setbacks.');
    }
    final coverage = data['coverage_limit'], fsi = data['fsi_limit'];
    if (coverage is num && width * depth > plotW * plotD * coverage / 100) return stop('The shop shell exceeds supplied plot coverage.');
    if (fsi is num && width * depth > plotW * plotD * fsi) return stop('The shop shell exceeds supplied FAR/FSI.');
    final sizes = <String,int>{};
    for (final field in retailCadFields.where((f) => f.kind == RequirementKind.decimal)) {
      if (!field.required && data[field.id] == null) continue;
      final value = mm(data[field.id]);
      if (value == null) return stop('Enter ${field.label.toLowerCase()} in metres.');
      sizes[field.id] = value;
    }
    int size(String key) => sizes['rt_$key']!;
    final count = data['rt_fixture_count'];
    if (count is! int || count < 1 || count > 24) return stop('Enter 1 to 24 measured fixture rows.');
    final ix = x + t, ir = r - t, iy = y + t, it = top - t;
    final clearWidth = ir - ix;
    final aisleW = size('aisle'), fixtureW = size('fixture_width'), fixtureD = size('fixture_depth');
    final counterW = size('checkout_width'), counterD = size('checkout_depth'), queueD = size('queue_depth');
    final publicDoorW = size('public_door'), stockDoorW = size('stock_door');
    final stockBottom = it - size('stock_depth'), salesTop = stockBottom - t;
    final frontTop = iy + aisleW, queueTop = frontTop + queueD, counterTop = queueTop + counterD;
    final bankBottom = counterTop + aisleW, bankTop = bankBottom + fixtureD;
    final aisleBankW = count * fixtureW + (count + 1) * aisleW;
    if (aisleBankW > clearWidth) {
      return stop('$count measured rows and ${count+1} aisles need ${(aisleBankW/1000).toStringAsFixed(2)} m of clear sales width; ${(clearWidth/1000).toStringAsFixed(2)} m is available.');
    }
    if (counterW + aisleW > clearWidth) return stop('Checkout and queue leave no clear connection between the entrance and display aisles.');
    if (bankTop + aisleW > salesTop) return stop('The shop is too shallow for checkout, queue, fixture length, front/rear cross-aisles and stock depth.');
    if (publicDoorW <= t || publicDoorW > aisleW || stockDoorW <= t || stockDoorW >= clearWidth || stockDoorW > size('stock_depth')) {
      return stop('An entrance or stock door does not fit the supplied wall, aisle or swing clearance.');
    }
    final sales = PlanRect(ix,iy,ir,salesTop), stock = PlanRect(ix,stockBottom,ir,it);
    for (final (name,value,room) in [('sales',data['sales_area'],sales), ('stock',data['stock_area'],stock)]) {
      if (value is num && room.area / 1000000 < value - .001) return stop('Measured clear $name area is below the requested area target.');
    }
    final routes = <MeasuredZone>[
      MeasuredZone('front','Front cross-aisle',PlanRect(ix,iy,ir,frontTop),'CUSTOMER_ROUTE'),
      MeasuredZone('connector','Entry to display',PlanRect(ix,frontTop,ix+aisleW,counterTop),'CUSTOMER_ROUTE'),
      MeasuredZone('cross','Display cross-aisle',PlanRect(ix,counterTop,ir,bankBottom),'CUSTOMER_ROUTE'),
      MeasuredZone('back','Rear cross-aisle',PlanRect(ix,bankTop,ir,salesTop),'CUSTOMER_ROUTE'),
    ];
    final obstacles = <MeasuredZone>[
      MeasuredZone('queue','Queue',PlanRect(ir-counterW,frontTop,ir,queueTop),'RETAIL_QUEUE'),
      MeasuredZone('counter','Checkout',PlanRect(ir-counterW,queueTop,ir,counterTop),'RETAIL_CHECKOUT'),
    ];
    final bankLeft = ix + (clearWidth - aisleBankW) ~/ 2;
    for (var i = 0; i <= count; i++) {
      final a = bankLeft + i * (fixtureW + aisleW);
      routes.add(MeasuredZone('aisle_$i','Aisle ${i+1}',PlanRect(a,bankBottom,a+aisleW,bankTop),'CUSTOMER_ROUTE'));
      if (i < count) obstacles.add(MeasuredZone('fixture_$i','Display ${i+1}',PlanRect(a+aisleW,bankBottom,a+aisleW+fixtureW,bankTop),'RETAIL_DISPLAY'));
    }
    final pubX = ix + (clearWidth - publicDoorW) ~/ 2, stockX = ix + (clearWidth - stockDoorW) ~/ 2;
    final entrance = PlanRect(pubX,y,pubX+publicDoorW,iy);
    final transfer = PlanRect(stockX,salesTop,stockX+stockDoorW,stockBottom);
    final walls = <PlanRect>[];
    void wall(int a,int b,int c,int d) { if (a<c && b<d) walls.add(PlanRect(a,b,c,d)); }
    wall(x,y,ix,top); wall(ir,y,r,top);
    wall(ix,y,pubX,iy); wall(pubX+publicDoorW,y,ir,iy);
    wall(ix,salesTop,stockX,stockBottom); wall(stockX+stockDoorW,salesTop,ir,stockBottom);
    final openings = <PlanOpening>[
      PlanOpening(PlanOpeningKind.door,entrance,AutomaticFloorPlan.entry,'retail_sales'),
      PlanOpening(PlanOpeningKind.door,transfer,'retail_sales','retail_stock'),
    ];
    final extras = <MeasuredZone>[];
    final rear = sizes['rt_rear_access'];
    if (rear != null) {
      if (top + rear > plotD) return stop('The specified rear staff approach extends beyond the measured plot.');
      if (size('stock_depth') < 2 * stockDoorW) return stop('The opposing stock doors need more clear depth to avoid overlapping swings.');
      final rearOpening = PlanRect(stockX,it,stockX+stockDoorW,top);
      wall(ix,it,stockX,top); wall(stockX+stockDoorW,it,ir,top);
      openings.add(PlanOpening(PlanOpeningKind.door,rearOpening,AutomaticFloorPlan.entry,'retail_stock'));
      extras.add(MeasuredZone('staff_approach','Rear staff approach',PlanRect(stockX,top,stockX+stockDoorW,top+rear),'RETAIL_SERVICE'));
    } else {
      wall(ix,it,ir,top);
    }
    bool shared(PlanRect a, PlanRect b) =>
      ((a.left == b.right || b.left == a.right) && a.bottom < b.top && b.bottom < a.top) ||
      ((a.bottom == b.top || b.bottom == a.top) && a.left < b.right && b.left < a.right);
    for (var i=0; i<routes.length; i++) {
      final a=routes[i].bounds;
      if (!sales.contains(a) || obstacles.any((o) => a.overlaps(o.bounds)) || routes.skip(i+1).any((o) => a.overlaps(o.bounds))) {
        return stop('A display, queue or aisle conflicts with another marked area.');
      }
    }
    final reached = {0};
    final stack = [0];
    while (stack.isNotEmpty) {
      final index = stack.removeLast();
      for (var i=0; i<routes.length; i++) {
        if (shared(routes[index].bounds,routes[i].bounds) && reached.add(i)) stack.add(i);
      }
    }
    if (reached.length != routes.length || !shared(entrance,routes.first.bounds) ||
        !shared(routes[3].bounds,transfer) || !shared(transfer,stock) || !shared(routes[0].bounds,obstacles[0].bounds)) {
      return stop('The entry does not connect to all display aisles, the queue or the stock door.');
    }
    if (obstacles.any((o) => !sales.contains(o.bounds))) return stop('A fixture or checkout falls outside the sales floor.');
    final rotated = facing == 'East' || facing == 'West';
    PlanRect orient(PlanRect b) => switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left),
      _=>b,
    };
    final type = taxonomyChoice(taxonomyGroup(taxonomyCategory('commercial'),'retail')!.types,selection.typeId)!;
    final plan = AutomaticFloorPlan(plot: rotated ? PlanRect(0,0,plotD,plotW) : PlanRect(0,0,plotW,plotD),
      footprint: orient(PlanRect(x,y,r,top)), facing: facing, sheetTitle: '${type.label} / RETAIL FIXTURES',
      rooms: [PlanRoom('retail_sales','Sales floor',orient(sales)), PlanRoom('retail_stock','Stock room',orient(stock))],
      walls: walls.map(orient), openings: openings.map((o)=>PlanOpening(o.kind,orient(o.bounds),o.from,o.to)));
    final issue = validatePlanPartition(plan);
    if (issue != null) return stop('Measured retail shell failed geometry checks: $issue');
    return RetailCadResult(plan,List.unmodifiable([...routes,...obstacles,...extras]
      .map((z)=>MeasuredZone(z.id,z.name,orient(z.bounds),z.layer))),null);
  }
}
