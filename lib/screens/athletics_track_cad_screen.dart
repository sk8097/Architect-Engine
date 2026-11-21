import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/athletics_track_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class AthleticsTrackCadScreen extends StatefulWidget {
  const AthleticsTrackCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<AthleticsTrackCadScreen> createState() => _AthleticsTrackCadScreenState();
}

class _AthleticsTrackCadScreenState extends State<AthleticsTrackCadScreen> {
  late final _result = AthleticsTrackCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _sharing = false;

  Future<void> _share(BuildContext context, String data, String extension, String mime) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: mime)],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_athletics_track.$extension'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not share the ${extension.toUpperCase()}.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Athletics track CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No athletics track drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.lanes.length} lanes · Lane 1 lap ${_result.lanes.first.lapM.toStringAsFixed(3)} m'),
          Text('Run-off envelope ${(_result.widthMm / 1000).toStringAsFixed(3)} × ${(_result.depthMm / 1000).toStringAsFixed(3)} m'),
          const Text('Blue: lane boundaries · Grey: measurement guides · Green: outer run-off · Red: common finish · Orange: one-lap staggers.'),
          Builder(builder: (button) => Wrap(spacing: 10, children: [
            FilledButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, drawing.toDxf(), 'dxf', 'application/dxf'), label: const Text('Share athletics track DXF')),
            OutlinedButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, _result.toCsv()!, 'csv', 'text/csv'), label: const Text('Share lane schedule CSV')),
          ])),
          CadPlanPreview(drawing: drawing),
          const Text('Geometric centreline marks only. No certified competition markings, break lines, grading, drainage, surfacing or rulebook approval.'),
        ],
      ],
    )));
  }
}
