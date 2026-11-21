import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/stepped_wall_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SteppedWallCadScreen extends StatefulWidget {
  const SteppedWallCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<SteppedWallCadScreen> createState() => _SteppedWallCadScreenState();
}

class _SteppedWallCadScreenState extends State<SteppedWallCadScreen> {
  late final _result = SteppedWallCadGenerator().generate(widget.brief);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, String data, String sheet, String extension, String mime) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: mime)],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_stepped_wall_$sheet.$extension'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not share the ${extension.toUpperCase()}.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _profile ? _result.profile : _result.plan;
    return Scaffold(appBar: AppBar(title: const Text('Surveyed stepped landscape wall CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No stepped wall drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Wall ${_m(_result.lengthMm)} m long × ${_m(_result.widthMm)} m thick · ${_result.runs.length} level runs'),
          Text('Gross wall envelope ${_result.grossM3.toStringAsFixed(3)} m³ · Maximum exposed height ${_m(_result.maxVisibleMm)} m'),
          Text('Minimum base depth ${_m(_result.minEmbedMm)} m · Minimum top margin ${_m(_result.minTopMarginMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Wall plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Longitudinal profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'Blue: wall · Orange: front ground · Green: back ground · Teal: wall steps · True scale'
            : 'Orange: front face · Green: back face · Teal: run boundaries · Grey: baseline'),
          Builder(builder: (button) => Wrap(spacing: 10, children: [
            FilledButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, drawing.toDxf(), _profile ? 'profile' : 'plan', 'dxf', 'application/dxf'),
              label: Text(_profile ? 'Share wall profile DXF' : 'Share wall plan DXF')),
            OutlinedButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, _result.toCsv()!, 'quantity', 'csv', 'text/csv'), label: const Text('Share wall quantity CSV')),
          ])),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          const Text('Geometry only. No footing, retained load, geotechnical stability, drainage, material specification or construction approval.'),
        ],
      ],
    )));
  }
}
