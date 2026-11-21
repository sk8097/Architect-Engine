import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/culvert_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class CulvertCadScreen extends StatefulWidget {
  const CulvertCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<CulvertCadScreen> createState() => _CulvertCadScreenState();
}

class _CulvertCadScreenState extends State<CulvertCadScreen> {
  late final _result = CulvertCadGenerator().generate(widget.brief);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_culvert_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Survey culvert crossing CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No culvert drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Barrel length ${_m(_result.lengthMm)} m · ${_result.gradePercent.toStringAsFixed(3)}% fall'),
          Text('Min. cover ${_m(_result.coverMm)} m at ch ${_m(_result.coverAtMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Crossing plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Barrel profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'Orange: surveyed surface · Blue: invert · Teal: outside crown · ${_result.exaggeration}× vertical exaggeration'
            : 'Blue: barrel and axis · Grey: road band · Purple: crossings and barrel ends'),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share barrel profile DXF' : 'Share crossing plan DXF')))),
          Text('Road band crosses the barrel centreline from ch ${_m(_result.roadStartMm)} to ${_m(_result.roadEndMm)} m.'),
          const Text('Cover uses the surveyed longitudinal centreline only, between the road edges. No hydraulic capacity, headwalls, structural cover acceptance or utility clearance is verified.'),
        ],
      ],
    )));
  }
}
