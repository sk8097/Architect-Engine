import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/transformer_bund_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class TransformerBundCadScreen extends StatefulWidget {
  const TransformerBundCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<TransformerBundCadScreen> createState() => _TransformerBundCadScreenState();
}

class _TransformerBundCadScreenState extends State<TransformerBundCadScreen> {
  late final _result = TransformerBundCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_transformer_bund_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Transformer bund CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No transformer bund drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Net geometric containment ${_result.netM3.toStringAsFixed(3)} m³'),
          Text('Gross ${_result.grossM3.toStringAsFixed(3)} m³ · Plinth displacement ${_result.displacedM3.toStringAsFixed(3)} m³'),
          Text('${_m(_result.freeboardMm)} m freeboard · ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m full envelope'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Bund plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Section A–A'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          const Text('Green: walls · Orange: solid plinths · Blue: design fill level in section'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share bund section DXF' : 'Share bund plan DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Geometry only. No spill or rainfall allowance, drainage, material specification, structural design or regulatory approval.'),
        ],
      ],
    )));
  }
}
