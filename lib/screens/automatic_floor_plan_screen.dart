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
      'DRAIN_PLAN_AXIS' || 'DRAIN_INVERT' => const Color(0xff265e99),
      'DRAIN_CROWN' => const Color(0xff007e8c),
      'DRAIN_NODES' || 'DRAIN_PROFILE_NODES' => const Color(0xff823a75),
      'DRAIN_FLOW' => const Color(0xff237d42),
      'DRAIN_GROUND' => const Color(0xffaa5c19),
      'PROFILE_GROUND' => const Color(0xffaa5c19),
      'PROFILE_DESIGN' => const Color(0xff265e99),
      'PROFILE_STATIONS' => const Color(0xff8993a6),
      'PROFILE_FILL' => const Color(0xff237d42),
      'PROFILE_CUT' => const Color(0xffa13445),
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
