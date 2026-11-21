import 'package:flutter/material.dart';

import '../models/project_brief.dart';
import '../services/automatic_floor_plan_generator.dart';
import '../services/hotel_wing_generator.dart';
import 'automatic_floor_plan_screen.dart';

class HotelWingScreen extends StatefulWidget {
  const HotelWingScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<HotelWingScreen> createState() => _HotelWingScreenState();
}

class _HotelWingScreenState extends State<HotelWingScreen> {
  late final _result = HotelWingGenerator().generate(widget.brief,
    widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);

  @override
  Widget build(BuildContext context) => AutomaticFloorPlanScreen(projectName: widget.name, brief: widget.brief,
    frontageFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing, title: 'Hotel guestroom wing CAD',
    entryDescription: _result.plan == null ? 'Measured guestroom wing' : '${_result.keys} keys in mirrored banks off the guest corridor',
    drawingLegend: 'Blue: beds and windows • Grey: bed clearances • Green: shared access and corridor.',
    siteZones: _result.zones,
    customResult: FloorPlanResult(_result.plan, [if (_result.issue != null) _result.issue!], const [
      'This is a single ground-floor wing, not a complete hotel. Bathroom reserves are unfurnished.',
      'No reception, accessible room, secondary egress, hotel operations, plumbing, ventilation or approvals are designed or verified.',
    ]));
}
