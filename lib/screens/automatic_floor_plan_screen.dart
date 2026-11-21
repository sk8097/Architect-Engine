import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/floor_plan_cad.dart';

class AutomaticFloorPlanScreen extends StatefulWidget {
  const AutomaticFloorPlanScreen({super.key, required this.projectName,
    required this.brief, required this.frontageFt, required this.depthFt, required this.facing,
    this.customResult, this.title = 'Automatic floor plan', this.siteZones = const [], this.entryDescription, this.drawingLegend});

  final String projectName, facing;
  final ProjectBrief brief;
  final FloorPlanResult? customResult;
  final String title;
  final String? entryDescription, drawingLegend;
  final List<MeasuredZone> siteZones;
  final double frontageFt, depthFt;

  @override
  State<AutomaticFloorPlanScreen> createState() => _AutomaticFloorPlanScreenState();
}

class _AutomaticFloorPlanScreenState extends State<AutomaticFloorPlanScreen> {
  late final _result = widget.customResult ?? AutomaticFloorPlanGenerator().generate(
    brief: widget.brief, frontageFt: widget.frontageFt, depthFt: widget.depthFt,
    facing: widget.facing,
  );

  late final _drawing = _result.plan == null ? null : FloorPlanCad.fromPlan(_result.plan!, siteZones: widget.siteZones);
  bool _sharing = false;

  Future<void> _shareDxf(BuildContext buttonContext, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = buttonContext.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final filename = widget.projectName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final name = '${filename.isEmpty ? 'floor_plan' : filename}_concept.dxf';
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([
        XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf'),
      ], fileNameOverrides: [name], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share the DXF. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _result.plan;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(widget.projectName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (plan == null) ...[
              Text('No plan generated', style: theme.textTheme.titleLarge),
              const Text('Your brief is saved. Edit it from Projects, then save to try again automatically.'),
              for (final issue in _result.issues)
                ListTile(contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.error_outline), title: Text(issue)),
            ] else ...[
              Text('${plan.sheetTitle ?? plan.configurationLabel} concept • ${widget.entryDescription ?? '${plan.facing} entry'}', style: theme.textTheme.titleLarge),
              const Text('Not for construction. Drawing units: millimetres.'),
              const SizedBox(height: 8),
              Builder(builder: (buttonContext) => Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : () => _shareDxf(buttonContext, _drawing!),
                  icon: const Icon(Icons.ios_share),
                  label: Text(_sharing ? 'Preparing DXF…' : 'Save or share DXF'),
                ),
              )),
              const SizedBox(height: 12),
              CadPlanPreview(plan: plan, drawing: _drawing!),
              const SizedBox(height: 8),
              if (widget.drawingLegend != null) Text(widget.drawingLegend!)
              else if (widget.siteZones.isNotEmpty)
                const Text('Orange: vehicle route • Green: staff route • Blue: dock bays. Pinch to zoom.')
              else const Text('Black: walls • Blue: windows • Green: door swings • N: north. Pinch to zoom.'),
              const SizedBox(height: 10),
              Text('Room schedule', style: theme.textTheme.titleLarge),
              for (final room in plan.rooms)
                ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(room.label),
                  subtitle: Text('${_metres(room.bounds.width)} × ${_metres(room.bounds.depth)} m (E–W × N–S)'),
                  trailing: Text('${(room.bounds.area / 1000000).toStringAsFixed(2)} m²')),
              Text('Building footprint: ${(plan.footprint.area / 1000000).toStringAsFixed(2)} m²'),
              const Divider(),
              for (final warning in _result.warnings)
                ListTile(contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline), title: Text(warning)),
              const Text('DXF opens as editable CAD geometry. PDF export is not available yet.'),
            ],
          ],
        ),
      ),
    );
  }

  String _metres(int mm) => (mm / 1000).toStringAsFixed(2);
}

class CadPlanPreview extends StatelessWidget {
  const CadPlanPreview({super.key, this.plan, required this.drawing});
  final AutomaticFloorPlan? plan;
  final FloorPlanCad drawing;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xfff5f7fa), borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(height: 340, child: InteractiveViewer(
      key: ObjectKey(drawing), maxScale: 10,
      child: CustomPaint(painter: _PlanPainter(plan, drawing), child: const SizedBox.expand()),
    )),
  );
}

class _PlanPainter extends CustomPainter {
  const _PlanPainter(this.plan, this.drawing);
  final AutomaticFloorPlan? plan;
  final FloorPlanCad drawing;

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 10.0;
    if (size.width <= margin * 2 || size.height <= margin * 2) return;
    final bounds = drawing.bounds;
    final scale = math.min((size.width - margin * 2) / bounds.width,
      (size.height - margin * 2) / bounds.depth);
    final left = (size.width - bounds.width * scale) / 2;
    final top = (size.height - bounds.depth * scale) / 2;
    Offset point(num x, num y) => Offset(left + (x.toDouble() - bounds.left) * scale,
      top + (bounds.top - y.toDouble()) * scale);
    Offset xy(CadPoint p) => point(p.x, p.y);
    Color color(String layer) => switch (layer) {
      'SURVEY_AXIS' => const Color(0xff1e648b),
      'SURVEY_STATIONS' => const Color(0xff823a75),
      'PAIRED_SHARED' => const Color(0xff237d42),
      'PAIRED_COUNTER' => const Color(0xffaa5c19),
      'PAIRED_CLEAR' => const Color(0xff8993a6),
      'RG_PLOT' => const Color(0xff666666),
      'RG_RESERVE' => const Color(0xff888888),
      'RG_RIM' => const Color(0xff237d42),
      'RG_WATER' => const Color(0xff265e99),
      'RG_BED' => const Color(0xff007e8c),
      'RG_MEDIA' => const Color(0xffaa5c19),
      'RG_AGG' => const Color(0xff7a4292),
      'RG_CUT' => const Color(0xff9b6d00),
      'RD_PLOT' || 'RD_END' => const Color(0xff777777),
      'RD_BAY' => const Color(0xff265e99),
      'RD_PUBLIC' => const Color(0xff007e8c),
      'RD_COLLECT' => const Color(0xffaa5c19),
      'SP_PLOT' || 'SP_RESERVE' || 'SP_STATION' => const Color(0xff777777),
      'SP_INLET' => const Color(0xff007e8c),
      'SP_CREST' => const Color(0xff237d42),
      'SP_CHUTE' => const Color(0xff265e99),
      'SP_APRON' => const Color(0xffaa5c19),
      'BY_PLOT' => const Color(0xff777777),
      'BY_LIMIT' => const Color(0xff237d42),
      'BY_UNIT' => const Color(0xff265e99),
      'BY_LANE' => const Color(0xff007e8c),
      'BY_CROSS' => const Color(0xffaa5c19),
      'VK_PLOT' || 'VK_EDGE' => const Color(0xff777777),
      'VK_DRIVE' => const Color(0xff265e99),
      'VK_BREAK' => const Color(0xffaa5c19),
      'VK_ARROW' => const Color(0xff007e8c),
      'VK_SOFFIT' => const Color(0xffaf2f2f),
      'VK_HEAD' => const Color(0xff237d42),
      'CS_PLOT' => const Color(0xff777777),
      'CS_HALL' => const Color(0xff454545),
      'CS_AISLE' => const Color(0xff007e8c),
      'CS_SCREEN' => const Color(0xff237d42),
      'CS_SEAT' => const Color(0xff265e99),
      'CS_BAY' => const Color(0xffaa5c19),
      'SS_PLOT' => const Color(0xff666666),
      'SS_LAND' => const Color(0xff237d42),
      'SS_UP_W' => const Color(0xff265e99),
      'SS_UP_E' => const Color(0xffaa5c19),
      'SS_ARROW' => const Color(0xff007e8c),
      'JR_PLOT' => const Color(0xff666666),
      'JR_RESERVE' => const Color(0xff909090),
      'JR_RUN' => const Color(0xff265e99),
      'JR_SAND' => const Color(0xffaa5c19),
      'JR_BOARD' => const Color(0xff237d42),
      'PAV_PLOT' => const Color(0xff757575),
      'PAV_FULL' => const Color(0xff265e99),
      'PAV_CUT' => const Color(0xffaa5c19),
      'CANOPY_ROOF' => const Color(0xff265e99),
      'CANOPY_POST' => const Color(0xffaa5c19),
      'CANOPY_WALK' => const Color(0xff237d42),
      'CANOPY_GRADE' => const Color(0xff757575),
      'REF_MEDIAN' => const Color(0xff858585),
      'REF_ROAD' => const Color(0xff555c65),
      'REF_CROSS' => const Color(0xffaa5c19),
      'REF_LAND' => const Color(0xff237d42),
      'REF_WALK' => const Color(0xff265e99),
      'REF_ROUTE' => const Color(0xff007e8c),
      'CYCLE_ROAD' => const Color(0xff555c65),
      'CYCLE_LIMIT' => const Color(0xff858585),
      'CYCLE_TRACK' => const Color(0xff265e99),
      'CYCLE_SEPARATOR' => const Color(0xff237d42),
      'CYCLE_DRIVEWAY' => const Color(0xffaa5c19),
      'PROM_SHORE' => const Color(0xff007e8c),
      'PROM_LIMIT' => const Color(0xff757575),
      'PROM_PATH' => const Color(0xff265e99),
      'PROM_PAD' => const Color(0xffaa5c19),
      'UP_AXIS' => const Color(0xff666666),
      'UP_LIMIT' => const Color(0xff909090),
      'UP_WALK' => const Color(0xff265e99),
      'UP_WALL' || 'UP_SOFFIT' => const Color(0xff237d42),
      'UP_PORTAL' => const Color(0xffaa5c19),
      'UP_HEAD' => const Color(0xff007e8c),
      'SW_AXIS' => const Color(0xff666666),
      'SW_FRONT' => const Color(0xffaa5c19),
      'SW_BACK' => const Color(0xff237d42),
      'SW_STEP' => const Color(0xff007e8c),
      'SW_ENVELOPE' => const Color(0xff265e99),
      'SL_AXIS' => const Color(0xff666666),
      'SL_ROW' => const Color(0xff909090),
      'SL_POLE' => const Color(0xff265e99),
      'SL_EXCLUDE' => const Color(0xffaf2f2f),
      'DUCT_AXIS' => const Color(0xff666666),
      'DUCT_BANK' => const Color(0xff265e99),
      'DUCT_GROUND' => const Color(0xff757575),
      'DUCT_CROSS' => const Color(0xffaa5c19),
      'DUCT_COVER' => const Color(0xff237d42),
      'DUCT_GAP' => const Color(0xff007e8c),
      'RAIL_AXIS' => const Color(0xff757575),
      'RAIL_EDGE' => const Color(0xff265e99),
      'RAIL_WALK' => const Color(0xff237d42),
      'RAIL_CUT' => const Color(0xffaa5c19),
      'WC_GALLERY' || 'WC_OPENING' || 'WC_ROUTE' => const Color(0xff237d42),
      'WC_FIXTURE' => const Color(0xff265e99),
      'WC_CIRCLE' => const Color(0xffaa5c19),
      'LIFT_APRON' || 'LIFT_OPENING' => const Color(0xff237d42),
      'LIFT_BAY_LIMIT' => const Color(0xff777777),
      'LIFT_VEHICLE' => const Color(0xff265e99),
      'LIFT_POST' => const Color(0xffaa5c19),
      'LIFT_HEAD' => const Color(0xffb43232),
      'TRACK_LANES' => const Color(0xff265e99),
      'TRACK_MEASURE' => const Color(0xff777777),
      'TRACK_RUNOFF' => const Color(0xff237d42),
      'TRACK_FINISH' => const Color(0xffb43232),
      'TRACK_STAGGER' => const Color(0xffaa5c19),
      'PLAY_SETBACK' => const Color(0xff757575),
      'PLAY_PATH' => const Color(0xff237d42),
      'PLAY_CLEARANCE' => const Color(0xffaa5c19),
      'PLAY_EQUIPMENT' => const Color(0xff265e99),
      'BIKE_MANOEUVRE' => const Color(0xff237d42),
      'BIKE_PARKED' => const Color(0xff265e99),
      'BIKE_STAND' => const Color(0xffaa5c19),
      'NICHE_VIEW' => const Color(0xff237d42),
      'NICHE_REAR' => const Color(0xff757575),
      'NICHE_POCKET' => const Color(0xff007e8c),
      'NICHE_OPENING' => const Color(0xff265e99),
      'NICHE_PLINTH' => const Color(0xffaa5c19),
      'TENNIS_SETBACK' => const Color(0xff757575),
      'TENNIS_RUNOFF' => const Color(0xff237d42),
      'TENNIS_DOUBLES' => const Color(0xff265e99),
      'TENNIS_SINGLES' => const Color(0xff75429a),
      'TENNIS_SERVICE' => const Color(0xff007e8c),
      'TENNIS_NET' => const Color(0xffaa5c19),
      'TWIN_TANK_SERVICE' => const Color(0xff237d42),
      'TWIN_TANK_CELL' => const Color(0xff265e99),
      'TWIN_TANK_NORMAL' => const Color(0xff007e8c),
      'TWIN_TANK_LOW' => const Color(0xffaa5c19),
      'COLD_RACK' => const Color(0xff265e99),
      'COLD_LOAD' => const Color(0xff007e8c),
      'COLD_FLUE' => const Color(0xffaa5c19),
      'COLD_ROUTE' => const Color(0xff237d42),
      'ANGLE_PARK_MARK' => const Color(0xff265e99),
      'ANGLE_PARK_FIT' => const Color(0xff007e8c),
      'ANGLE_PARK_DRIVE' || 'ANGLE_PARK_FLOW' => const Color(0xff823a75),
      'ANGLE_PARK_LIMIT' => const Color(0xff237d42),
      'GALLERY_PANEL' => const Color(0xff265e99),
      'GALLERY_FACE' => const Color(0xffaa5c19),
      'GALLERY_VIEW' => const Color(0xff237d42),
      'GALLERY_SPINE' => const Color(0xff823a75),
      'WINDROW_YARD' => const Color(0xff237d42),
      'WINDROW_TOE' => const Color(0xff265e99),
      'WINDROW_TOP' => const Color(0xff007e8c),
      'WINDROW_HIPS' || 'WINDROW_FACE' => const Color(0xffaa5c19),
      'PARK_LOOP_OUTER' || 'PARK_LOOP_INNER' => const Color(0xff265e99),
      'PARK_LOOP_AXIS' => const Color(0xff007e8c),
      'PARK_LOOP_ENTRY' => const Color(0xff823a75),
      'PARK_LOOP_LAWN' => const Color(0xff237d42),
      'AMPH_STAGE' => const Color(0xffaa5c19),
      'AMPH_TIERS' => const Color(0xff265e99),
      'AMPH_PLACES' || 'AMPH_EYES' => const Color(0xff007e8c),
      'AMPH_RESERVES' => const Color(0xff237d42),
      'AMPH_SIGHT' => const Color(0xff823a75),
      'GARDEN_PATHS' => const Color(0xff237d42),
      'GARDEN_BED_WALL' => const Color(0xffaa5c19),
      'GARDEN_GROWING' => const Color(0xff265e99),
      'MARKET_STALL' => const Color(0xff265e99),
      'MARKET_LOOP' || 'MARKET_AISLE' => const Color(0xff237d42),
      'MARKET_ENTRY' => const Color(0xff823a75),
      'POOL_WATER' => const Color(0xff265e99),
      'POOL_LANES' => const Color(0xff007e8c),
      'POOL_DECK' => const Color(0xff237d42),
      'POOL_BREAKS' => const Color(0xff823a75),
      'POOL_FLOOR' => const Color(0xffaa5c19),
      'RAIN_ROOF' => const Color(0xffaa5c19),
      'RAIN_TANK' || 'RAIN_TANK_INNER' => const Color(0xff265e99),
      'RAIN_SERVICE' => const Color(0xff237d42),
      'BASKET_KEY' || 'BASKET_LINES' => const Color(0xff265e99),
      'BASKET_THREE' => const Color(0xff823a75),
      'BASKET_RIM' => const Color(0xffa13445),
      'BASKET_RUNOFF' || 'BASKET_APPROACH' => const Color(0xff237d42),
      'HOTEL_WING_BED' => const Color(0xff265e99),
      'HOTEL_WING_CLEAR' => const Color(0xff8993a6),
      'HOTEL_WING_ROUTE' => const Color(0xff237d42),
      'TEACH_LAB_BENCH' => const Color(0xff265e99),
      'TEACH_LAB_COUNTER' => const Color(0xffaa5c19),
      'TEACH_LAB_CLEAR' => const Color(0xff8993a6),
      'TEACH_LAB_ROUTE' => const Color(0xff237d42),
      'RAMP_FLIGHT' => const Color(0xff265e99),
      'RAMP_LANDING' => const Color(0xff237d42),
      'RAMP_SEPARATOR' => const Color(0xff8993a6),
      'RAMP_CLEAR' || 'RAMP_PATH' => const Color(0xff823a75),
      'ORCHARD_CANOPY' || 'ORCHARD_CENTRE' => const Color(0xff237d42),
      'ORCHARD_HEADLAND' || 'ORCHARD_LANE' => const Color(0xffaa5c19),
      'ORCHARD_EXCLUSION' => const Color(0xffa13445),
      'EV_DRIVE' => const Color(0xff8993a6),
      'EV_WALK' || 'EV_HEAD_PASS' => const Color(0xff237d42),
      'EV_TRANSFER' => const Color(0xff823a75),
      'EV_PADS' || 'EV_EQUIPMENT' => const Color(0xffaa5c19),
      'EV_BAYS' => const Color(0xff265e99),
      'BASIN_CREST' => const Color(0xffaa5c19),
      'BASIN_NORMAL' => const Color(0xff237d42),
      'BASIN_DESIGN' => const Color(0xff265e99),
      'BASIN_FREEBOARD' => const Color(0xff823a75),
      'BASIN_SECTION_LINE' => const Color(0xff8993a6),
      'PV_BUILDABLE' => const Color(0xff8993a6),
      'PV_MODULE' => const Color(0xff265e99),
      'PV_LOW_EDGE' => const Color(0xff237d42),
      'PV_EXCLUSION' => const Color(0xffa13445),
      'PV_SHADOW_LIMIT' => const Color(0xff823a75),
      'TRUCK_APRON' => const Color(0xff8993a6),
      'TRUCK_BAY' => const Color(0xffaa5c19),
      'TRUCK_OBSTACLE' => const Color(0xffa13445),
      'TRUCK_AXLE' => const Color(0xff265e99),
      'TRUCK_CLEAR_SWEEP' => const Color(0xff823a75),
      'CULVERT_ROAD' || 'CULVERT_ROAD_AXIS' => const Color(0xff8993a6),
      'CULVERT_BARREL' || 'CULVERT_INVERT' || 'CULVERT_BARREL_AXIS' => const Color(0xff265e99),
      'CULVERT_CROWN' => const Color(0xff007e8c),
      'CULVERT_SURFACE' => const Color(0xffaa5c19),
      'CULVERT_COVER' || 'CULVERT_CONTROLS' => const Color(0xff823a75),
      'FOOTBRIDGE_DECK' => const Color(0xff265e99),
      'FOOTBRIDGE_APPROACH' => const Color(0xff237d42),
      'FOOTBRIDGE_SOFFIT' => const Color(0xffaa5c19),
      'FOOTBRIDGE_WATER' || 'FOOTBRIDGE_CHANNEL' => const Color(0xff007e8c),
      'FOOTBRIDGE_AXIS' || 'FOOTBRIDGE_CLEARANCE' => const Color(0xff823a75),
      'LAYBY_EDGE' => const Color(0xff265e99),
      'LAYBY_BERTH' => const Color(0xff007e8c),
      'LAYBY_BOARD' || 'LAYBY_TRAVEL' => const Color(0xff823a75),
      'LAYBY_SHELTER' => const Color(0xffaa5c19),
      'LAYBY_WALK' => const Color(0xff237d42),
      'OPEN_DRAIN_BANK' => const Color(0xffaa5c19),
      'OPEN_DRAIN_BOTTOM' => const Color(0xff265e99),
      'OPEN_DRAIN_AXIS' => const Color(0xff823a75),
      'OPEN_DRAIN_REF' => const Color(0xff007e8c),
      'OPEN_DRAIN_STRIP' => const Color(0xff237d42),
      'DRAIN_PLAN_AXIS' || 'DRAIN_INVERT' => const Color(0xff265e99),
      'DRAIN_CROWN' => const Color(0xff007e8c),
      'DRAIN_NODES' || 'DRAIN_PROFILE_NODES' => const Color(0xff823a75),
      'DRAIN_FLOW' => const Color(0xff237d42),
      'DRAIN_GROUND' => const Color(0xffaa5c19),
      'PROFILE_GROUND' || 'SECTION_GROUND' => const Color(0xffaa5c19),
      'PROFILE_DESIGN' || 'SECTION_DESIGN' => const Color(0xff265e99),
      'PROFILE_STATIONS' || 'SECTION_AXES' => const Color(0xff8993a6),
      'PROFILE_FILL' || 'SECTION_FILL' => const Color(0xff237d42),
      'PROFILE_CUT' || 'SECTION_CUT' => const Color(0xffa13445),
      'PROFILE_CURVE_POINTS' => const Color(0xff823a75),
      'WARD_ROUTE' => const Color(0xff237d42),
      'WARD_BEDS' => const Color(0xff265e99),
      'WARD_COUNTER' => const Color(0xffaa5c19),
      'WARD_CLEAR' => const Color(0xff8993a6),
      'SHARED_CORE_APPROACH' => const Color(0xffaa5c19),
      'SHARED_CORE_LOBBY' => const Color(0xff237d42),
      'SHARED_CORE_SHAFT' => const Color(0xff823a75),
      'JUNCTION_AXIS' => const Color(0xff1e648b),
      'JUNCTION_ROW' => const Color(0xff757e8b),
      'JUNCTION_CURB' => const Color(0xff237d42),
      'JUNCTION_CONTROLS' => const Color(0xff823a75),
      'RIGHT_OF_WAY' => const Color(0xff4f5868),
      'CORRIDOR_BANDS' => const Color(0xff1d7137),
      'PLOT' => const Color(0xff7c8798),
      'DOORS' => const Color(0xff127d4d),
      'WINDOWS' => const Color(0xff0072a7),
      'DIMENSIONS' => const Color(0xff455977),
      'SCHOOL_ARRIVAL' || 'SCHOOL_ENTRY_WALK' => const Color(0xffaa5c19),
      'SCHOOL_LEARNING' => const Color(0xff224aa9),
      'SCHOOL_PLAYGROUND' => const Color(0xff237d42),
      'SCHOOL_PLAY_WALK' => const Color(0xff076986),
      'SCHOOL_PLAY_FENCE' => const Color(0xff626b77),
      'SCHOOL_THRESHOLD' => const Color(0xff823a75),
      'MIXED_SHOP_ACCESS' => const Color(0xffaa5c19),
      'MIXED_HOME_ACCESS' => const Color(0xff237e44),
      'MIXED_DIVIDER' => const Color(0xff823a75),
      'CROSS_DOCK_INBOUND' => const Color(0xffaa5c19),
      'CROSS_DOCK_OUTBOUND' => const Color(0xff265e99),
      'CROSS_DOCK_STAGING' => const Color(0xff777454),
      'CROSS_DOCK_FLOW' => const Color(0xff823a75),
      'PACKHOUSE_FLOW' => const Color(0xff237e44),
      'PACKHOUSE_PADS' => const Color(0xffaa5c19),
      'PACKHOUSE_OPENINGS' => const Color(0xff823a75),
      'PARKING_BAYS' => const Color(0xff076986),
      'VEHICLE_APPROACH' => const Color(0xff823a75),
      'PEDESTRIAN_APPROACH' => const Color(0xff1d7137),
      'GROUND_PLATE_REFERENCE' => const Color(0xff8993a6),
      'BADMINTON_COURTS' || 'BADMINTON_LINES' => const Color(0xff265e99),
      'BADMINTON_NET' || 'BADMINTON_VIEW_DIVIDER' => const Color(0xff823a75),
      'BADMINTON_RUNOFF' => const Color(0xff8993a6),
      'BADMINTON_PLAYERS' => const Color(0xff237d42),
      'BADMINTON_SPECTATOR' => const Color(0xffaa5c19),
      'GREENHOUSE_BENCHES' => const Color(0xff237d42),
      'GREENHOUSE_AISLES' => const Color(0xff8993a6),
      'GREENHOUSE_HEADLAND' || 'GREENHOUSE_APPROACH' => const Color(0xffaa5c19),
      'GREENHOUSE_IRR_HEADER' || 'GREENHOUSE_IRR_LATERALS' => const Color(0xff265e99),
      'HOSTEL_BEDS' => const Color(0xff265e99),
      'HOSTEL_LOCKERS' => const Color(0xffaa5c19),
      'HOSTEL_BED_CLEAR' => const Color(0xff8993a6),
      'HOSTEL_AISLES' => const Color(0xff237d42),
      'BADMINTON_SEATS' => const Color(0xff006f91),
      'LIBRARY_PUBLIC' => const Color(0xffaa5c19),
      'LIBRARY_QUIET' || 'LIBRARY_DESKS' || 'LIBRARY_SHELVES' => const Color(0xff265e99),
      'LIBRARY_QUIET_THRESHOLD' => const Color(0xff823a75),
      'LIBRARY_STACK_AISLES' || 'LIBRARY_STUDY_AISLE' => const Color(0xff237d42),
      'LIBRARY_CHAIR_CLEAR' => const Color(0xff737f92),
      'ASSEMBLY_MATERIAL' => const Color(0xff087778),
      'ASSEMBLY_OPENINGS' => const Color(0xff823a75),
      'ASSEMBLY_STAFF' || 'ASSEMBLY_WORK_AISLE' => const Color(0xff237d42),
      'ASSEMBLY_PADS' => const Color(0xffaa5c19),
      'ASSEMBLY_BENCHES' => const Color(0xff265e99),
      'ASSEMBLY_CLEARANCE' => const Color(0xff737f92),
      'DAIRY_FEED_ACCESS' => const Color(0xff237d42),
      'DAIRY_CLEAN_ACCESS' => const Color(0xffaa5c19),
      'DAIRY_TROUGHS' => const Color(0xff265e99),
      'DAIRY_PEN_GATES' => const Color(0xff823a75),
      'FOOD_GUEST_AISLES' => const Color(0xff237d42),
      'FOOD_SERVE_PASS' => const Color(0xff087778),
      'FOOD_RETURN_PASS' => const Color(0xffaa5c19),
      'FOOD_SERVICE_PADS' => const Color(0xff823a75),
      'FOOD_TABLES' => const Color(0xff265e99),
      'FOOD_SEATS' => const Color(0xff737f92),
      'OFFICE_VISITOR_ROUTE' => const Color(0xffaa5c19),
      'OFFICE_STAFF_ROUTE' => const Color(0xff265e99),
      'OFFICE_THRESHOLD' => const Color(0xff823a75),
      'OFFICE_DESKS' => const Color(0xff006f91),
      'OFFICE_CHAIR_CLEAR' => const Color(0xff737f92),
      'OFFICE_AISLES' => const Color(0xff237d42),
      'TERRACE_ACCESS' => const Color(0xff823a75),
      'TERRACE_DECK' => const Color(0xff237d42),
      'STAIRS' => const Color(0xff354ba0),
      'PATIENT_ROUTE' => const Color(0xff006f91),
      'SERVICE_ROUTE' => const Color(0xffa65f17),
      'CUSTOMER_ROUTE' => const Color(0xff007d87),
      'RETAIL_QUEUE' => const Color(0xffa65f17),
      'RETAIL_CHECKOUT' => const Color(0xff7051a0),
      'RETAIL_SERVICE' => const Color(0xff237e44),
      'VEHICLE_ROUTE' => const Color(0xffac4d0b),
      'WALK_ROUTE' => const Color(0xff237e44),
      'DOCK_BAYS' || 'DOCK_OPENINGS' => const Color(0xff1666a5),
      'ZONES_PUBLIC' => const Color(0xff007d87),
      'ZONES_SERVICE' => const Color(0xff8f4b10),
      'PLANNING_ENVELOPE' => const Color(0xff775ea4),
      _ => const Color(0xff182537),
    };
    final wallFill = Paint()..color = const Color(0xffa8b6c6);
    for (final wall in plan?.walls ?? const <PlanRect>[]) {
      canvas.drawRect(Rect.fromPoints(point(wall.left, wall.top), point(wall.right, wall.bottom)), wallFill);
    }
    for (final line in drawing.lines) {
      canvas.drawLine(xy(line.start), xy(line.end), Paint()
        ..color = color(line.layer)..strokeWidth = line.layer == 'WALLS' ? 1.25 : 0.7);
    }
    for (final arc in drawing.arcs) {
      final end=arc.end<arc.start?arc.end+360:arc.end;
      canvas.drawArc(Rect.fromCircle(center: xy(arc.center), radius: arc.radius.toDouble() * scale),
        -end * math.pi / 180, (end - arc.start) * math.pi / 180, false,
        Paint()..style = PaintingStyle.stroke..color = color(arc.layer)..strokeWidth = 0.8);
    }
    for (final label in drawing.labels) {
      final font = label.height.toDouble() * scale;
      // Keep the full plot visible; tiny room/dimension text can be zoomed.
      final text = TextPainter(text: TextSpan(text: label.text,
        style: TextStyle(color: color(label.layer), fontSize: math.max(1.0, font), fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();
      final anchor = xy(label.at);
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(-label.angle * math.pi / 180);
      text.paint(canvas, Offset(-text.width / 2, -text.height * 0.83));
      canvas.restore();
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(_PlanPainter oldDelegate) => oldDelegate.drawing != drawing;
}
