import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/facade_louvre_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class FacadeLouvreCadScreen extends StatefulWidget {
  const FacadeLouvreCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<FacadeLouvreCadScreen> createState() => _FacadeLouvreCadScreenState();
}

class _FacadeLouvreCadScreenState extends State<FacadeLouvreCadScreen> {
  late final _result = FacadeLouvreCadGenerator().generate(widget.brief);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_facade_louvre_$sheet.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _section ? _result.section : _result.elevation;
    return Scaffold(appBar: AppBar(title: const Text('Façade louvre CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No façade louvre drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.count} blades · ${_m(_result.spanMm)} m span · ${_m(_result.clearMm)} m clear gap'),
          Text('Lower angle: ${_result.lowerOpen.toStringAsFixed(3)}% directly lit · Higher angle: ${_result.upperShade.toStringAsFixed(3)}% shaded'),
          Text('Full cut-off ${_result.cutoffDeg.toStringAsFixed(3)}° · Actual top reserve ${_m(_result.headMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Exterior elevation'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Section A–A'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          const Text('Green: blades · Blue: lower-angle ray · Orange: higher-angle ray'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'elevation'),
            label: Text(_section ? 'Share louvre section DXF' : 'Share louvre elevation DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Geometry only. Complete gaps only. No jamb or end effects, annual sun path, daylight performance, fixings or approval.'),
        ],
      ],
    )));
  }
}
