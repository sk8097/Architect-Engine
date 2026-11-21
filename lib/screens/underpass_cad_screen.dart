import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/underpass_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class UnderpassCadScreen extends StatefulWidget {
  const UnderpassCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<UnderpassCadScreen> createState() => _UnderpassCadScreenState();
}

class _UnderpassCadScreenState extends State<UnderpassCadScreen> {
  late final _result = UnderpassCadGenerator().generate(widget.brief);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_underpass_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Surveyed pedestrian underpass CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No pedestrian underpass drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Route ${_m(_result.lengthMm)} m · Covered span ${_m(_result.coveredMm)} m · Clear width ${_m(_result.clearMm)} m'),
          Text('Minimum vertical headroom ${_m(_result.minHeadMm)} m at Ch ${_m(_result.headStationMm)} m'),
          Text('Maximum absolute walkway grade ${_result.maxGrade.toStringAsFixed(3)}%'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Underpass plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Longitudinal profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'Blue: walkway level · Green: underside level · Orange: portals · Teal: lowest headroom · True scale'
            : 'Blue: walkway · Grey: centreline and corridor · Green: wall envelopes · Orange: portals'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share underpass profile DXF' : 'Share underpass plan DXF')))),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          const Text('Geometry only. No crossfall, edge obstructions, accessible landings, drainage, flood, traffic or structural approval.'),
        ],
      ],
    )));
  }
}
