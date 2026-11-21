import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/stacked_retail_cad_generator.dart';
import 'tower_planner_screen.dart';

class StackedRetailCadScreen extends StatefulWidget {
  const StackedRetailCadScreen({super.key,required this.name,required this.brief,
    required this.widthFt,required this.depthFt,required this.facing});
  final String name,facing;
  final double widthFt,depthFt;
  final ProjectBrief brief;

  @override
  State<StackedRetailCadScreen> createState()=>_StackedRetailCadScreenState();
}

class _StackedRetailCadScreenState extends State<StackedRetailCadScreen> {
  late final _result=StackedRetailCadGenerator().generate(widget.brief,
    widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context)=>TowerPlanScreen.stackedRetail(projectName:widget.name,
    generated:_result,areaSqft:widget.widthFt*widget.depthFt);
}
