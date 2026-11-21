import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/paired_apartment_generator.dart';
import 'automatic_floor_plan_screen.dart';

class PairedApartmentScreen extends StatefulWidget {
  const PairedApartmentScreen({super.key,required this.name,required this.brief,
    required this.widthFt,required this.depthFt,required this.facing});
  final String name,facing;
  final double widthFt,depthFt;
  final ProjectBrief brief;

  @override
  State<PairedApartmentScreen> createState()=>_PairedApartmentScreenState();
}

class _PairedApartmentScreenState extends State<PairedApartmentScreen> {
  late final _result=PairedApartmentGenerator().generate(widget.brief,widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>AutomaticFloorPlanScreen(projectName:widget.name,brief:widget.brief,
    frontageFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing,title:'Paired apartment CAD',
    entryDescription:'Two mirrored 1 BHK flats with separate doors off the same lobby',
    drawingLegend:'Green: common entrance and lobby • Orange: kitchen run • Grey: working clearance • Blue: windows.',
    siteZones:_result.zones,
    customResult:FloorPlanResult(_result.plan,[if(_result.issue!=null) _result.issue!],const [
      'The shared service room and bathrooms are space reserves only. No sanitary fixtures, service routing or meters are designed.',
      'Window openings and clearances are measured geometry, not daylight, accessibility, acoustic separation or fire-egress verification.',
    ]));
}
