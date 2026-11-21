import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/hostel_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class HostelCadScreen extends StatefulWidget {
  const HostelCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<HostelCadScreen> createState() => _HostelCadScreenState();
}

class _HostelCadScreenState extends State<HostelCadScreen> {
  late final _result = HostelCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'Shared-room hostel CAD',
    entryDescription: 'Front warden room, shared washroom reserve and furnished bedrooms off one passage',
    drawingLegend: 'Blue: single beds • Orange: lockers • Grey: bedside clearances • Green: clear aisles.',
    siteZones: _result.fixtures,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'The toilet and bath room is an enclosed reserve only. Fixtures, plumbing and ventilation are not designed.',
      'Resident count and clearances are user inputs, not verified occupancy, accessibility, window performance or emergency egress.',
    ]));
}
