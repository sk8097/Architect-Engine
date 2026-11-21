import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/school_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SchoolCadScreen extends StatefulWidget {
  const SchoolCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<SchoolCadScreen> createState() => _SchoolCadScreenState();
}

class _SchoolCadScreenState extends State<SchoolCadScreen> {
  late final _result = SchoolCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'Primary school CAD',
    entryDescription: 'Visitor lobby and separate learning passage',
    drawingLegend: 'Orange: visitor arrival • Blue: student passage • Purple: internal threshold door.',
    siteZones: _result.siteZones,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'The internal door identifies the monitored threshold; hardware, locks and supervision are not specified.',
      'This is a circulation concept, not an egress plan. Exit count and travel distance, student capacity, accessibility, daylight and authority requirements need separate review.',
    ]));
}
