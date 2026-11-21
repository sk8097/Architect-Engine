import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/shared_core_cad_generator.dart';
import 'tower_planner_screen.dart';

class SharedCoreCadScreen extends StatefulWidget {
  const SharedCoreCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<SharedCoreCadScreen> createState() => _SharedCoreCadScreenState();
}

class _SharedCoreCadScreenState extends State<SharedCoreCadScreen> {
  late final _result = SharedCoreCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => TowerPlanScreen.sharedCore(projectName: widget.name,
    generated: _result, areaSqft: widget.widthFt * widget.depthFt);
}
