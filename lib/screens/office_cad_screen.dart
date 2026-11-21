import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/office_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class OfficeCadScreen extends StatefulWidget {
  const OfficeCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<OfficeCadScreen> createState() => _OfficeCadScreenState();
}

class _OfficeCadScreenState extends State<OfficeCadScreen> {
  late final _result = OfficeCadGenerator().generate(widget.brief,
    widthFt:widget.widthFt, depthFt:widget.depthFt, facing:widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Office workplace CAD',
    entryDescription:'Reception and meeting rooms before the staff threshold',
    drawingLegend:'Orange: visitor passage • Purple: threshold • Blue: staff passage • Green: workspace aisles • Grey: chair clearances.',
    siteZones:_result.fixtures,
    customResult:FloorPlanResult(_result.plan,[if(_result.issue != null) _result.issue!],const [
      'Concept only: desk and chair clearances are supplied dimensions. Door controls, ergonomic fit, accessibility, occupancy and emergency egress are not verified.',
    ]));
}
