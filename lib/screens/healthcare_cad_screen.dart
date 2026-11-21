import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/healthcare_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class HealthcareCadScreen extends StatefulWidget {
  const HealthcareCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<HealthcareCadScreen> createState() => _HealthcareCadScreenState();
}

class _HealthcareCadScreenState extends State<HealthcareCadScreen> {
  late final _result = HealthcareCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'Clinic route CAD',
    entryDescription: 'Independent patient and service entrances',
    drawingLegend: 'Blue: patient route • Orange: staff/service route. Pinch to zoom.',
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'Outpatient concept only. The wings have no internal connection. People or supplies that must pass between wings would have to go outside; outdoor routes have not been planned.',
      'This is not a hospital plan. Infection control, sterile/dirty flows, patient accessibility, emergency exits and clinical licensing need independent verification.',
    ]));
}
