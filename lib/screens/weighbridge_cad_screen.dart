import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/weighbridge_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class WeighbridgeCadScreen extends StatefulWidget {
  const WeighbridgeCadScreen({super.key, required this.name, required this.brief, required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<WeighbridgeCadScreen> createState() => _WeighbridgeCadScreenState();
}

class _WeighbridgeCadScreenState extends State<WeighbridgeCadScreen> {
  late final _result = WeighbridgeCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _sharing = false;

  Future<void> _share(BuildContext context, String data, String extension, String mime) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: mime)],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_weighbridge.$extension'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not share the ${extension.toUpperCase()}.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Freight weighbridge CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No weighbridge drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Rearmost axle stop range: Ch ${_m(_result.fromMm)}–${_m(_result.toMm)} m'),
          Text('Truck shown at midpoint Ch ${_m(_result.stopMm)} m · ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m full envelope'),
          const Text('Green: platform · Blue: truck body · Red: axles · Orange: stop range marker · Teal: bypass.'),
          Builder(builder: (button) => Wrap(spacing: 10, children: [
            FilledButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, drawing.toDxf(), 'dxf', 'application/dxf'), label: const Text('Share weighbridge plan DXF')),
            OutlinedButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, _result.toCsv()!, 'csv', 'text/csv'), label: const Text('Share axle schedule CSV')),
          ])),
          CadPlanPreview(drawing: drawing),
          const Text('Static set-out only. No weighing accuracy, axle loads, braking, gradients, vehicle turning or traffic approval.'),
        ],
      ],
    )));
  }
}
