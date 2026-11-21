import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/detention_basin_generator.dart';
import 'automatic_floor_plan_screen.dart';

class DetentionBasinScreen extends StatefulWidget {
  const DetentionBasinScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<DetentionBasinScreen> createState() => _DetentionBasinScreenState();
}

class _DetentionBasinScreenState extends State<DetentionBasinScreen> {
  late final _result = DetentionBasinGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_basin_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Detention basin CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No basin drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Active storage ${_result.activeStorageM3.toStringAsFixed(3)} m³ · Freeboard ${_m(_result.freeboardMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Basin plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Section A–A'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          Text(_section
            ? 'True-scale section, west to east. Orange: side slopes · Purple: freeboard.'
            : 'Blue: design water · Green: normal pool · Orange: inner crest · Grey: section cut.'),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share basin section DXF' : 'Share basin plan DXF')))),
          const Text('Geometric storage only. No rainfall routing, outlet sizing, embankment stability, seepage or safety design is included.'),
          ExpansionTile(title: const Text('Stage–storage schedule'), children: [
            for (final stage in _result.stages) ListTile(dense: true,
              title: Text('${stage.label} · ${_m(stage.levelMm)} m'),
              subtitle: Text('Area ${stage.areaM2.toStringAsFixed(3)} m² · Storage ${stage.storageM3.toStringAsFixed(3)} m³')),
          ]),
        ],
      ],
    )));
  }
}
