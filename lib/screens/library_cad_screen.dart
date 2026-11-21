import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/library_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class LibraryCadScreen extends StatefulWidget {
  const LibraryCadScreen({super.key,required this.name,required this.brief,
    required this.widthFt,required this.depthFt,required this.facing});
  final String name,facing;
  final double widthFt,depthFt;
  final ProjectBrief brief;

  @override
  State<LibraryCadScreen> createState()=>_LibraryCadScreenState();
}

class _LibraryCadScreenState extends State<LibraryCadScreen> {
  late final _result=LibraryCadGenerator().generate(widget.brief,widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Library reading CAD',
    entryDescription:'Public checkout and shelves · Separate quiet reading passage',
    drawingLegend:'Orange: public passage • Purple: quiet threshold • Blue: shelving and desks • Green: fixture aisles • Grey: chair clearances.',
    siteZones:_result.fixtures,
    customResult:FloorPlanResult(_result.plan,[if(_result.issue!=null) _result.issue!],const [
      'The quiet threshold is a wall and door in plan, not an acoustic performance or access-control specification.',
      'The supplied shelf and desk clearances are not accessibility, shelf load, ergonomic, occupancy or fire-egress verification.',
    ]));
}
