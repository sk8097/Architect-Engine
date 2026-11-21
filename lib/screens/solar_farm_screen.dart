import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/solar_farm_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SolarFarmScreen extends StatefulWidget {
  const SolarFarmScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<SolarFarmScreen> createState() => _SolarFarmScreenState();
}

class _SolarFarmScreenState extends State<SolarFarmScreen> {
  late final _result = SolarFarmGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_solar_fixed_tilt.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Fixed-tilt solar farm CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No array drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.tables} tables · ${_result.modules} modules · ${_result.peakKw.toStringAsFixed(3)} kWp DC'),
          Text('Projected table depth ${_m(_result.projectedDepthMm)} m · Rise ${_m(_result.riseMm)} m'),
          if (_result.rowGapMm case final gap?)
            Text('Clear row gap ${_m(gap)} m · Rear shade reach at design angle ${_m(_result.shadowMm)} m'),
          const Text('Blue: modules · Green: low edges · Purple: rear shade limit · Red: exclusions · Grey: buildable limit.'),
          CadPlanPreview(drawing: drawing),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing), label: const Text('Share solar layout DXF')))),
          const Text('Shade check assumes a common level for all low edges and tests one perpendicular sun profile angle only. No annual shading, generation, electrical design, road access or structural checks are included.'),
        ],
      ],
    )));
  }
}
