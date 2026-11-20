import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';

class AutomaticFloorPlanScreen extends StatefulWidget {
  const AutomaticFloorPlanScreen({super.key, required this.projectName,
    required this.brief, required this.frontageFt, required this.depthFt, required this.facing});

  final String projectName, facing;
  final ProjectBrief brief;
  final double frontageFt, depthFt;

  @override
  State<AutomaticFloorPlanScreen> createState() => _AutomaticFloorPlanScreenState();
}

class _AutomaticFloorPlanScreenState extends State<AutomaticFloorPlanScreen> {
  late final _result = AutomaticFloorPlanGenerator().generate(
    brief: widget.brief, frontageFt: widget.frontageFt, depthFt: widget.depthFt,
    facing: widget.facing,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _result.plan;
    return Scaffold(
      appBar: AppBar(title: const Text('Automatic floor plan')),
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
              Text('1 BHK concept • ${plan.facing} entry', style: theme.textTheme.titleLarge),
              const Text('Not for construction. Dimensions are shown in metres.'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: const Color(0xfff5f7fa),
                  borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(height: 340, child: InteractiveViewer(
                  maxScale: 6,
                  child: CustomPaint(painter: _PlanPainter(plan), child: const SizedBox.expand()),
                )),
              ),
              const SizedBox(height: 8),
              const Text('Black: walls • Blue: windows • Green: entrance • N: north. Pinch to zoom.'),
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
              const Text('DXF and PDF export are not part of this preview release.'),
            ],
          ],
        ),
      ),
    );
  }

  String _metres(int mm) => (mm / 1000).toStringAsFixed(2);
}

class _PlanPainter extends CustomPainter {
  const _PlanPainter(this.plan);
  final AutomaticFloorPlan plan;

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 22.0;
    if (size.width <= margin * 2 || size.height <= margin * 2) return;
    final scale = math.min((size.width - margin * 2) / plan.plot.width,
      (size.height - margin * 2) / plan.plot.depth);
    final left = (size.width - plan.plot.width * scale) / 2;
    final top = (size.height - plan.plot.depth * scale) / 2;
    Rect rect(PlanRect r) => Rect.fromLTRB(left + r.left * scale,
      top + (plan.plot.top - r.top) * scale, left + r.right * scale,
      top + (plan.plot.top - r.bottom) * scale);
    final stroke = Paint()..color = const Color(0xff6b778c)..style = PaintingStyle.stroke;
    canvas.drawRect(rect(plan.plot), stroke);
    final roomFill = Paint()..color = const Color(0xffdbe8f4);
    for (final room in plan.rooms) { canvas.drawRect(rect(room.bounds), roomFill); }
    final wallFill = Paint()..color = const Color(0xff172333);
    for (final wall in plan.walls) { canvas.drawRect(rect(wall), wallFill); }
    final window = Paint()..color = const Color(0xff0074bd)..strokeWidth = 2;
    for (final opening in plan.openings) {
      final r = rect(opening.bounds);
      if (opening.kind == PlanOpeningKind.window) {
        if (r.width >= r.height) {
          canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), window);
        } else {
          canvas.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), window);
        }
      } else if (opening.from == AutomaticFloorPlan.entry) {
        canvas.drawRect(r.inflate(2), Paint()..color = const Color(0xff19834c));
      }
    }
    void label(String value, Offset center, double maxWidth) {
      if (maxWidth < 22) return;
      final text = TextPainter(text: TextSpan(text: value,
        style: const TextStyle(color: Color(0xff172333), fontSize: 10, fontWeight: FontWeight.w600)),
        textAlign: TextAlign.center, textDirection: TextDirection.ltr, maxLines: 2, ellipsis: '…')
        ..layout(maxWidth: maxWidth);
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
      text.dispose();
    }
    for (final room in plan.rooms) {
      final r = rect(room.bounds);
      if (r.height >= 30) label(room.label, r.center, r.width - 5);
    }
    label('↑ N', const Offset(25, 12), 42);
  }

  @override
  bool shouldRepaint(_PlanPainter oldDelegate) => oldDelegate.plan != plan;
}
