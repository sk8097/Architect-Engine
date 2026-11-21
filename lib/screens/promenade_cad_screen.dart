import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/promenade_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class PromenadeCadScreen extends StatefulWidget {
  const PromenadeCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<PromenadeCadScreen> createState() => _PromenadeCadScreenState();
}

class _PromenadeCadScreenState extends State<PromenadeCadScreen> {
  late final _result = PromenadeCadGenerator().generate(widget.brief);
  bool _sharing = false;

  Future<void> _share(BuildContext context, String data, String extension, String mime) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: mime)],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_promenade.$extension'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Surveyed promenade CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No promenade drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Path ${_m(_result.lengthMm)} m long × ${_m(_result.widthMm)} m wide · ${_result.pads.length} lookout pads'),
          Text('Minimum shore gap ${_m(_result.minShoreMm)} m · Inland gap ${_m(_result.minInlandMm)} m (normal to baseline)'),
          Text('Path ${_result.pathAreaM2.toStringAsFixed(3)} m² · Added pads ${_result.padAreaM2.toStringAsFixed(3)} m²'),
          const Text('Teal: surveyed shoreline · Grey: inland boundary · Blue: path · Orange: lookout pads.'),
          Builder(builder: (button) => Wrap(spacing: 10, children: [
            FilledButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, drawing.toDxf(), 'dxf', 'application/dxf'), label: const Text('Share promenade DXF')),
            OutlinedButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, _result.toCsv()!, 'csv', 'text/csv'), label: const Text('Share lookout schedule CSV')),
          ])),
          CadPlanPreview(drawing: drawing),
          const Text('Horizontal reference only. No flood, erosion, coastal setback, drainage, structure, guarding or accessibility approval.'),
        ],
      ],
    )));
  }
}
