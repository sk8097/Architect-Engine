import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/refuge_crossing_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class RefugeCrossingCadScreen extends StatefulWidget {
  const RefugeCrossingCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<RefugeCrossingCadScreen> createState() => _RefugeCrossingCadScreenState();
}

class _RefugeCrossingCadScreenState extends State<RefugeCrossingCadScreen> {
  late final _result = RefugeCrossingCadGenerator().generate(widget.brief);
  bool _sharing = false;

  Future<void> _share(BuildContext context, String data) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_pedestrian_refuge.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Surveyed pedestrian refuge CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No pedestrian refuge drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_m(_result.crossingMm)} m crossing width · ${_m(_result.walkMm)} m clear median walk'),
          Text('${_m(_result.staggerMm)} m centre-to-centre stagger · ${_m(_result.openingGapMm)} m between opening edges'),
          Text('${_m(_result.reserveMm)} m reserve each side of connector · ${_m(_result.routeMm)} m centreline route across both roads and landings'),
          const Text('Grey: street edges · Orange: carriageway crossings · Blue: refuge walk · Green: landings · Teal: route centreline.'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing.toDxf()), label: const Text('Share pedestrian refuge DXF')))),
          CadPlanPreview(drawing: drawing),
          const Text('Horizontal envelopes only. No curb ramps, turning clearance, signal or marking design, sight distance, accessibility or traffic safety approval.'),
        ],
      ],
    )));
  }
}
