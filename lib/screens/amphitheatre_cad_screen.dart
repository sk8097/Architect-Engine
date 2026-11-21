import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/amphitheatre_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class AmphitheatreCadScreen extends StatefulWidget {
  const AmphitheatreCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<AmphitheatreCadScreen> createState() => _AmphitheatreCadScreenState();
}

class _AmphitheatreCadScreenState extends State<AmphitheatreCadScreen> {
  late final _result = AmphitheatreCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_amphitheatre_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Outdoor amphitheatre CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No amphitheatre drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.rows} rows × ${_result.placesPerRow} places · ${_result.places} nominal places'),
          Text('Envelope ${_m(_result.envelopeWidthMm)} × ${_m(_result.envelopeDepthMm)} m'),
          Text('Minimum centreline clearance ${_m(_result.clearanceMm)} m at row ${_result.criticalRow}'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Amphitheatre plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Centreline section'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          Text(_section
            ? 'Orange: stage · Blue: treads · Teal: eyes · Purple: critical sightline and clearance · True scale'
            : 'Orange: stage · Blue: seating tiers · Teal: nominal place marks · Green: side and rear reserves'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share seating section DXF' : 'Share amphitheatre plan DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Centreline only. No full-stage visibility, structure, access stairs, egress, accessibility or approved occupancy check.'),
        ],
      ],
    )));
  }
}
