import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/warehouse_loading_generator.dart';
import 'automatic_floor_plan_screen.dart';

class WarehouseLoadingScreen extends StatefulWidget {
  const WarehouseLoadingScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<WarehouseLoadingScreen> createState() => _WarehouseLoadingScreenState();
}

class _WarehouseLoadingScreenState extends State<WarehouseLoadingScreen> {
  late final _result = WarehouseLoadingGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name,
    brief: widget.brief, frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing,
    title: 'Warehouse loading CAD', siteZones: _result.zones,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'Vehicle and staff approach footprints do not overlap. The internal staff aisle is marked only; pedestrian protection and crossings need specialist review.',
      'Manoeuvring is a dimensioned reserve, not a verified swept path. No truck reversing trajectory, dock level, ramp, rack aisles, fire access or street connection has been designed.',
    ]));
}
