import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/stormwater_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class StormwaterCadScreen extends StatefulWidget {
  const StormwaterCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<StormwaterCadScreen> createState() => _StormwaterCadScreenState();
}

class _StormwaterCadScreenState extends State<StormwaterCadScreen> {
  late final _result = StormwaterCadGenerator().generate(widget.brief);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_drainage_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Stormwater plan + profile CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No stormwater drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Survey plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Pipe profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'Orange: surveyed ground · Blue: pipe invert · Teal: outside crown · ${_result.exaggeration}× vertical exaggeration'
            : 'Blue: drain axis · Purple: survey nodes (symbols not to scale) · Green: downstream arrows'),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share pipe profile DXF' : 'Share survey plan DXF')))),
          const Text('Only geometric fall and cover along the supplied ground line are checked. No hydraulic capacity, tailwater, structure, utility clashes or discharge approval is verified.'),
          ExpansionTile(title: const Text('Reach schedule (true dimensions)'), children: [
            for (final r in _result.reaches) ListTile(dense: true, title: Text('${r.upstream.id} → ${r.downstream.id} · ${_m(r.length)} m'),
              subtitle: Text('Invert ${_m(r.upstream.invert)} → ${_m(r.downstream.invert)} m · ${r.gradePercent.toStringAsFixed(3)}% fall\n'
                'Min. cover ${_m(r.minimumCover)} m at ch ${_m(r.minimumCoverAt)} m')),
          ]),
        ],
      ],
    )));
  }
}
