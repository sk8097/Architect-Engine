import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/retail_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class RetailCadScreen extends StatefulWidget {
  const RetailCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<RetailCadScreen> createState() => _RetailCadScreenState();
}

class _RetailCadScreenState extends State<RetailCadScreen> {
  late final _result = RetailCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name,
    brief: widget.brief, frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing,
    title: 'Retail fixture CAD', siteZones: _result.zones,
    drawingLegend: 'Teal: customer aisles • Orange: queue • Purple: checkout • Green: stock access. Pinch to zoom.',
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'Single-shop concept. Display fixtures and queue are kept outside the measured aisle footprints. This is not an occupancy, accessibility or emergency exit check.',
      'Stock access uses a door off the rear aisle. Optional rear staff approach is a dimensioned on-site reserve, not a verified delivery or street route.',
    ]));
}
