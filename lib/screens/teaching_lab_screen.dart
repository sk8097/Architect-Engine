import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/teaching_lab_generator.dart';
import 'automatic_floor_plan_screen.dart';

class TeachingLabScreen extends StatefulWidget {
  const TeachingLabScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<TeachingLabScreen> createState() => _TeachingLabScreenState();
}

class _TeachingLabScreenState extends State<TeachingLabScreen> {
  late final _result = TeachingLabGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'Teaching lab CAD',
    entryDescription: _result.plan == null ? 'Measured teaching laboratory and prep room' : '${_result.places} student places in two banks of measured benches',
    drawingLegend: 'Blue: student benches • Orange: teacher and prep counters • Grey: work zones • Green: circulation and cross aisles.',
    siteZones: _result.zones,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'This draws a single general teaching lab and enclosed prep room, not the school. Student places are a dimensional count, not an occupancy approval.',
      'No experiments, specialist equipment, gas, ventilation, plumbing, emergency egress, accessibility or approvals are designed or verified.',
    ]));
}
