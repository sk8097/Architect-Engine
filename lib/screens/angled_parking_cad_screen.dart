import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/angled_parking_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class AngledParkingCadScreen extends StatefulWidget {
  const AngledParkingCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<AngledParkingCadScreen> createState() => _AngledParkingCadScreenState();
}

class _AngledParkingCadScreenState extends State<AngledParkingCadScreen> {
  late final _result = AngledParkingCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_angled_parking.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Angled surface parking CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No surface parking drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.spaces} stalls at ${_result.angle}° · Envelope ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m'),
          Text('Along-aisle pitch ${_m(_result.pitchMm)} m · Marked row depth ${_m(_result.rowDepthMm)} m'),
          const Text('Blue: stall markings · Teal: static rectangular fit (coincides with marks at 90°) · Purple: through aisle · Green: envelope.'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing), label: const Text('Share parking plan DXF')))),
          CadPlanPreview(drawing: drawing),
          const Text('Static geometry only. No swept paths, pedestrian or accessible bays, grading, drainage, or approval of external access or traffic flow.'),
        ],
      ],
    )));
  }
}
