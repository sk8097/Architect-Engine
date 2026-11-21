import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/greenhouse_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class GreenhouseCadScreen extends StatefulWidget {
  const GreenhouseCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<GreenhouseCadScreen> createState() => _GreenhouseCadScreenState();
}

class _GreenhouseCadScreenState extends State<GreenhouseCadScreen> {
  late final _result = GreenhouseCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'Greenhouse bench CAD',
    entryDescription: 'Growing benches on both sides of a door-aligned main aisle',
    drawingLegend: 'Green: bench footprints • Grey: parallel aisles • Orange: working space and approach • Blue: optional irrigation schematic.',
    siteZones: _result.zones,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], [
      if (_result.plan != null) 'Total growing bench footprint: ${(_result.benchAreaMm2 / 1000000).toStringAsFixed(2)} m².',
      'Irrigation lines, if selected, are routing references only. No pipes, pressure, flow, crop demand or installation heights are specified.',
      'No structural frame, glazing, drainage, ventilation, accessibility or emergency egress design is included.',
    ]));
}
