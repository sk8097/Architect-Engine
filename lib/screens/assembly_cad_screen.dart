import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/assembly_cad_generator.dart';
import '../services/automatic_floor_plan_generator.dart';
import 'automatic_floor_plan_screen.dart';

class AssemblyCadScreen extends StatefulWidget {
  const AssemblyCadScreen({super.key,required this.name,required this.brief,required this.widthFt,required this.depthFt,required this.facing});
  final String name,facing;
  final double widthFt,depthFt;
  final ProjectBrief brief;

  @override
  State<AssemblyCadScreen> createState()=>_AssemblyCadScreenState();
}

class _AssemblyCadScreenState extends State<AssemblyCadScreen> {
  late final _result=AssemblyCadGenerator().generate(widget.brief,widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Factory assembly CAD',
    entryDescription:'Opposite-end material movement and a separate staff passage',
    drawingLegend:'Teal: material lane • Purple: transfer openings • Orange: pads • Green: staff/work routes • Blue: benches • Grey: working clearances.',
    siteZones:_result.zones,
    customResult:FloorPlanResult(_result.plan,[if(_result.issue!=null) _result.issue!],const [
      'Planned routes and clearances are geometric. Doors connect workers to production and quality control; separation of moving equipment and people in operation is not verified.',
      'Review machinery, guarding, loads, utilities, ergonomics, workplace safety, fire/egress and vehicle manoeuvres separately.',
    ]));
}
