import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/footbridge_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class FootbridgeCadScreen extends StatefulWidget {
  const FootbridgeCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<FootbridgeCadScreen> createState() => _FootbridgeCadScreenState();
}

class _FootbridgeCadScreenState extends State<FootbridgeCadScreen> {
  late final _result = FootbridgeCadGenerator().generate(widget.brief);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_footbridge_$sheet.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _profile ? _result.profile : _result.plan;
    return Scaffold(appBar: AppBar(title: const Text('Surveyed footbridge CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No footbridge drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Deck span ${_m(_result.spanMm)} m · Tie-ins ${_m(_result.lengthMm)} m apart'),
          Text('Approach A ${_result.gradeA.toStringAsFixed(3)}% · B ${_result.gradeB.toStringAsFixed(3)}% · Reference clearance ${_m(_result.clearanceMm)} m'),
          Text('Full-width coverage needed from ch ${_m(_result.requiredStartMm)} to ${_m(_result.requiredEndMm)} m.'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Footbridge plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Deck profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'Blue: deck · Orange: underside · Teal: reference water level · Green: approaches · True scale'
            : 'Blue: deck · Green: approaches · Grey: channel banks · Teal: channel axis'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share footbridge profile DXF' : 'Share footbridge plan DXF')))),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          const Text('Geometry only. No loads, foundations, landings, terrain tie-ins beyond the controls, flood levels, guarding or accessibility are verified.'),
        ],
      ],
    )));
  }
}
