import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/inpatient_ward_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class InpatientWardCadScreen extends StatefulWidget {
  const InpatientWardCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<InpatientWardCadScreen> createState() => _InpatientWardCadScreenState();
}

class _InpatientWardCadScreenState extends State<InpatientWardCadScreen> {
  late final _result = InpatientWardCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'General inpatient ward CAD',
    entryDescription: 'Nursing lobby and two banks of measured bed bays',
    drawingLegend: 'Blue: beds • Orange: nursing counter • Grey: bedside and staff clearances • Green: access aisle and end clearances.',
    siteZones: _result.zones,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'This draws one general ward, not a hospital, ICU or isolation suite. The washroom is an enclosed reserve with no fixtures or plumbing.',
      'Bed count and aisle clearances are supplied inputs. No clinical standard, bed-transfer swept path, accessibility, egress, ventilation or medical utilities are verified.',
    ]));
}
