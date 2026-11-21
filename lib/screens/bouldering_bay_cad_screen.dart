import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/bouldering_bay_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class BoulderingBayCadScreen extends StatefulWidget {
  const BoulderingBayCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<BoulderingBayCadScreen> createState() => _BoulderingBayCadScreenState();
}

class _BoulderingBayCadScreenState extends State<BoulderingBayCadScreen> {
  late final _result = BoulderingBayCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_bouldering_bay_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Bouldering bay CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No bouldering bay drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Lip height ${_m(_result.heightMm)} m · ${_result.angle.toStringAsFixed(3)}° from vertical'),
          Text('${_m(_result.lipGapMm)} m overhead gap · ${_m(_result.matBeyondMm)} m mat beyond lip'),
          Text('Measured panel surface ${_result.panelM2.toStringAsFixed(3)} m²'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Bay plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Section A–A'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          const Text('Blue: wall panels · Orange: mat extent · Teal: access strip · Green: lip overhead gap'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share bay section DXF' : 'Share bay plan DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Geometry only. No fall-path assessment, mat performance, anchors, routes, structural or climbing safety approval.'),
        ],
      ],
    )));
  }
}
