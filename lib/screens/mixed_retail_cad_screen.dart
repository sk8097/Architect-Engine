import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/mixed_retail_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class MixedRetailCadScreen extends StatefulWidget {
  const MixedRetailCadScreen({super.key,required this.name,required this.brief,
    required this.widthFt,required this.depthFt,required this.facing});
  final String name,facing;
  final double widthFt,depthFt;
  final ProjectBrief brief;

  @override
  State<MixedRetailCadScreen> createState()=>_MixedRetailCadScreenState();
}

class _MixedRetailCadScreenState extends State<MixedRetailCadScreen> {
  late final _result=MixedRetailCadGenerator().generate(widget.brief,
    widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Shop and dwelling CAD',
    entryDescription:'Independent shop and home entrances',
    drawingLegend:'Orange: shop walk • Green: home walk • Purple: solid divider. Interior retail fixtures have their own layers.',
    siteZones:_result.zones,
    customResult:FloorPlanResult(_result.plan,[if (_result.issue!=null) _result.issue!],const [
      'Side-by-side, one floor only. The paths stop at the plot boundary. Right of access beyond the plot is not verified.',
      'Solid divider shows geometric separation only. Verify fire rating, egress, utilities, exhaust, acoustics, accessibility and local mixed-use permissions separately.',
    ]));
}
