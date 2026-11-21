import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/cattle_shed_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class CattleShedCadScreen extends StatefulWidget {
  const CattleShedCadScreen({super.key,required this.name,required this.brief,required this.widthFt,required this.depthFt,required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<CattleShedCadScreen> createState()=>_CattleShedCadScreenState();
}

class _CattleShedCadScreenState extends State<CattleShedCadScreen> {
  late final _result=CattleShedCadGenerator().generate(widget.brief,widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Cattle shed CAD',
    entryDescription:'Front feed lane · Off-side pen gates and rear cleaning access',
    drawingLegend:'Green: feed route • Orange: cleaning alleys and pads • Blue: feed troughs • Purple: pen gates.',
    siteZones:_result.zones,
    customResult:FloorPlanResult(_result.plan,[if(_result.issue!=null) _result.issue!],[
      if(_result.plan!=null) 'Planned places from your assumptions: ${_result.plannedCapacity}. No welfare stocking density is verified.',
      'The rear pads are not manure storage, a drainage design or a vehicle manoeuvring assessment.',
      'Specialist review is needed for animal handling, welfare, ventilation, watering, floor falls, waste management and farm approvals.',
    ]));
}
