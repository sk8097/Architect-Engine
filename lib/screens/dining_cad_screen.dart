import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/dining_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class DiningCadScreen extends StatefulWidget {
  const DiningCadScreen({super.key,required this.name,required this.brief,
    required this.widthFt,required this.depthFt,required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<DiningCadScreen> createState()=>_DiningCadScreenState();
}

class _DiningCadScreenState extends State<DiningCadScreen> {
  late final _result=DiningCadGenerator().generate(widget.brief,
    widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Dine-in service CAD',
    entryDescription:'Customer entrance · Separate serving and used-dish hatches',
    drawingLegend:'Green: customer aisles • Blue: tables • Grey: chair clearances • Teal: serving pass • Orange: used-dish return • Purple: rear service pads.',
    siteZones:_result.zones,
    customResult:FloorPlanResult(_result.plan,[if(_result.issue!=null) _result.issue!],const [
      'Hatches and rear doors separate the kitchen and dishwashing room in plan. The dining aisle is shared; separate hygienic routes are not verified.',
      'Toilet room is an enclosure reserve. No equipment, plumbing, ventilation, accessible fixtures, fire egress, hygiene or approvals are verified.',
    ]));
}
