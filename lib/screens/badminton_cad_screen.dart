import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/badminton_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class BadmintonCadScreen extends StatefulWidget {
  const BadmintonCadScreen({super.key,required this.name,required this.brief,required this.widthFt,required this.depthFt,required this.facing});
  final String name,facing;
  final double widthFt,depthFt;
  final ProjectBrief brief;

  @override
  State<BadmintonCadScreen> createState()=>_BadmintonCadScreenState();
}

class _BadmintonCadScreenState extends State<BadmintonCadScreen> {
  late final _result=BadmintonCadGenerator().generate(widget.brief,widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Indoor badminton CAD',
    entryDescription:'Measured playing lines and run-offs with player-side changing access',
    drawingLegend:'Blue: court lines • Purple: net or glazing • Grey: clear run-off envelope • Green: player approach • Orange: spectator route.',
    siteZones:_result.zones,
    customResult:FloorPlanResult(_result.plan,[if(_result.issue!=null) _result.issue!],const [
      'User-provided playing and run-off dimensions are not checked against competition rules. Net height, surface, lighting, clear height and glazing safety are not designed.',
      'Changing and viewing enclosures are concept reserves. Accessibility, occupancy, emergency exits and crowd safety need separate review.',
    ]));
}
