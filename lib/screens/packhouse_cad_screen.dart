import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/packhouse_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class PackhouseCadScreen extends StatefulWidget {
  const PackhouseCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<PackhouseCadScreen> createState() => _PackhouseCadScreenState();
}

class _PackhouseCadScreenState extends State<PackhouseCadScreen> {
  late final _result = PackhouseCadGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'Packhouse goods-flow CAD',
    entryDescription: 'Front receiving · Opposite-side dispatch',
    drawingLegend: 'Green: one-way goods lane • Orange: handling pads • Purple: material openings.',
    siteZones: _result.zones,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'Dry ambient goods handling concept only. The material openings and pads are not personnel exits or vehicle turning designs.',
      'Review worker access and egress, equipment, drainage, food safety, ventilation and local licensing separately. No wet or refrigerated processing is drawn.',
    ]));
}
