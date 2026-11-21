import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/warehouse_loading_generator.dart';
import '../services/cross_dock_cad_generator.dart';
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
  late final _crossDock=CrossDockCadGenerator.requested(widget.brief);
  late final _result=_crossDock
    ? CrossDockCadGenerator().generate(widget.brief,widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing)
    : WarehouseLoadingGenerator().generate(widget.brief,widthFt:widget.widthFt,depthFt:widget.depthFt,facing:widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name,
    brief: widget.brief, frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing,
    title: _crossDock?'Warehouse cross-dock CAD':'Warehouse loading CAD', siteZones: _result.zones,
    entryDescription:_crossDock?'Opposing vehicle banks and independent side staff entry':null,
    drawingLegend:_crossDock?'Orange: inbound bank • Blue: outbound bank • Purple: transfer lane • Green: side staff approach.':null,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], _crossDock?const [
      'The side aisle has a door into the freight hall. Internal pedestrian protection, workplace separation and staff amenities are not designed.',
      'The yards are measured reserves, not truck turning/reversing checks. Vehicle access beyond the plot, grades, dock levellers, fire exits and operating permits need separate design.',
    ]:const [
      'Vehicle and staff approach footprints do not overlap. The internal staff aisle is marked only; pedestrian protection and crossings need specialist review.',
      'Manoeuvring is a dimensioned reserve, not a verified swept path. No truck reversing trajectory, dock level, ramp, rack aisles, fire access or street connection has been designed.',
    ]));
}
