import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/skate_transition_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SkateTransitionCadScreen extends StatefulWidget {
  const SkateTransitionCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<SkateTransitionCadScreen> createState() => _SkateTransitionCadScreenState();
}

class _SkateTransitionCadScreenState extends State<SkateTransitionCadScreen> {
  late final _result = SkateTransitionCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_skate_transition_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Skate transition CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No skate transition drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Lip height ${_m(_result.riseMm)} m · Lip tangent ${_result.lipAngle.toStringAsFixed(3)}°'),
          Text('${_m(_result.curveRunMm)} m horizontal curve run · ${_m(_result.curveLengthMm)} m arc length'),
          Text('Full envelope ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Transition plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Longitudinal profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          const Text('Teal: flat run-in · Blue: circular transition · Green: upper deck'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share transition profile DXF' : 'Share transition plan DXF')))),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          const Text('Geometry only. No coping, edge protection, fall zones, drainage, structure, rideability or safety approval.'),
        ],
      ],
    )));
  }
}
