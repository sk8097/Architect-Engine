import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/switchback_stair_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SwitchbackStairCadScreen extends StatefulWidget {
  const SwitchbackStairCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<SwitchbackStairCadScreen> createState() => _SwitchbackStairCadScreenState();
}

class _SwitchbackStairCadScreenState extends State<SwitchbackStairCadScreen> {
  late final _result = SwitchbackStairCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _elevation = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_switchback_stair_$sheet.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _elevation ? _result.elevation : _result.plan;
    return Scaffold(appBar: AppBar(title: const Text('Outdoor switchback stair CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No switchback stair drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.risers} risers per flight · ${_result.riserMm.toStringAsFixed(3)} mm uniform riser · ${_m(_result.runMm)} m run per flight'),
          Text('Full envelope ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m · Turn landing RL ${_m(_result.turnRlMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Stair plan'), selected: !_elevation, onSelected: (_) => setState(() => _elevation = false)),
            ChoiceChip(label: const Text('Side elevation'), selected: _elevation, onSelected: (_) => setState(() => _elevation = true)),
          ]),
          Text(_elevation
            ? 'Blue: west flight · Orange: east flight · Green: landings · True-scale superposed side elevation'
            : 'Blue: west flight · Orange: east flight · Green: landings · Teal arrows show ascent'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _elevation ? 'elevation' : 'plan'),
            label: Text(_elevation ? 'Share stair elevation DXF' : 'Share stair plan DXF')))),
          CadPlanPreview(key: ValueKey(_elevation), drawing: drawing),
          const Text('Geometry only. No handrails, guards, nosings, headroom, structure, accessible route or egress approval.'),
        ],
      ],
    )));
  }
}
