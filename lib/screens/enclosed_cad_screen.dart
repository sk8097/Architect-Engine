import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/enclosed_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class EnclosedCadScreen extends StatefulWidget {
  const EnclosedCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<EnclosedCadScreen> createState() => _EnclosedCadScreenState();
}

class _EnclosedCadScreenState extends State<EnclosedCadScreen> {
  late final _result = EnclosedCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name,
    brief: widget.brief, frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing,
    title: 'Measured floor plan CAD', customResult: FloorPlanResult(
      _result.sheets.isEmpty ? null : _result.sheets.single.plan, _result.issues, const [
        'Single-storey concept. The drawing checks fit, room dimensions and connected passage, not engineering or legal compliance.',
        'Access and daylight performance, building services, equipment clearances, fire safety and local approvals need separate verification.',
        'Unallocated rectangles are not occupiable rooms. No existing structure or terrain is inferred.',
      ]));
}
