import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/silage_bunker_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SilageBunkerCadScreen extends StatefulWidget {
  const SilageBunkerCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<SilageBunkerCadScreen> createState() => _SilageBunkerCadScreenState();
}

class _SilageBunkerCadScreenState extends State<SilageBunkerCadScreen> {
  late final _result = SilageBunkerCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_silage_bunker_$sheet.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _section ? _result.section : _result.plan;
    return Scaffold(appBar: AppBar(title: const Text('Silage bunker CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No silage bunker drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Geometric fill volume ${_result.volumeM3.toStringAsFixed(3)} m³'),
          Text('Floor ${_result.floorGrade.toStringAsFixed(3)}% · Fill face ${_result.faceGrade.toStringAsFixed(3)}% · ${_m(_result.freeMm)} m freeboard'),
          Text('Full envelope ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Bunker plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Section A–A'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          const Text('Green: walls · Orange: fill face · Blue: fill crest in section · Teal: apron and floor'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share bunker section DXF' : 'Share bunker plan DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Geometry only. No storage mass, pile stability, compaction, leachate, structures or operating approval.'),
        ],
      ],
    )));
  }
}
