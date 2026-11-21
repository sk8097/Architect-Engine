import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/dwelling_g1_generator.dart';
import 'tower_planner_screen.dart';

class DwellingG1Screen extends StatefulWidget {
  const DwellingG1Screen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<DwellingG1Screen> createState() => _DwellingG1ScreenState();
}

class _DwellingG1ScreenState extends State<DwellingG1Screen> {
  late final _result = DwellingG1Generator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => TowerPlanScreen.dwelling(projectName: widget.name,
    generated: _result, areaSqft: widget.widthFt * widget.depthFt);
}
