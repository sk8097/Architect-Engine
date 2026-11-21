import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/plaza_paving_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class PlazaPavingCadScreen extends StatefulWidget {
  const PlazaPavingCadScreen({super.key, required this.name, required this.brief, required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<PlazaPavingCadScreen> createState() => _PlazaPavingCadScreenState();
}

class _PlazaPavingCadScreenState extends State<PlazaPavingCadScreen> {
  late final _result = PlazaPavingCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _sharing = false;

  Future<void> _share(BuildContext context, String data, String extension, String mime) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: mime)],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_plaza_paving.$extension'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not share the ${extension.toUpperCase()}.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Urban plaza paving CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No plaza paving drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.columns} columns × ${_result.rows} rows · ${_result.fullCount} full pieces · ${_result.cutCount} cut pieces'),
          Text('Paving ${_result.grossM2.toStringAsFixed(3)} m² · Plan area of joints ${_result.jointM2.toStringAsFixed(3)} m²'),
          const Text('Grey: plot · Blue: full pieces · Orange: cut pieces.'),
          Builder(builder: (button) => Wrap(spacing: 10, children: [
            FilledButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, drawing.toDxf(), 'dxf', 'application/dxf'), label: const Text('Share paving plan DXF')),
            OutlinedButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, _result.toCsv()!, 'csv', 'text/csv'), label: const Text('Share paving cut schedule CSV')),
          ])),
          CadPlanPreview(drawing: drawing),
          const Text('Installed geometry only. No stock optimisation, kerf, waste, spares, bedding, drainage or installation approval.'),
        ],
      ],
    )));
  }
}
