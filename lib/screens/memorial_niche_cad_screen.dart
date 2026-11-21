import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/memorial_niche_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class MemorialNicheCadScreen extends StatefulWidget {
  const MemorialNicheCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<MemorialNicheCadScreen> createState() => _MemorialNicheCadScreenState();
}

class _MemorialNicheCadScreenState extends State<MemorialNicheCadScreen> {
  late final _result = MemorialNicheCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _elevation = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_memorial_niche_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Memorial niche wall CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No memorial niche drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.capacity} nominal niches · Layout ${_m(_result.bankWidthMm)} × ${_m(_result.bankDepthMm)} m'),
          Text('Typical panel ${_m(_result.panelWidthMm)} m wide × ${_m(_result.panelHeightMm)} m high × ${_m(_result.panelDepthMm)} m deep'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Site plan'), selected: !_elevation, onSelected: (_) => setState(() => _elevation = false)),
            ChoiceChip(label: const Text('Typical elevation'), selected: _elevation, onSelected: (_) => setState(() => _elevation = true)),
          ]),
          Text(_elevation
            ? 'Blue: clear niche openings · Orange: plinth top when present · True scale'
            : 'Teal: projected pockets · Green: viewing strips and end reserves · Grey: rear reserve on single-face layout'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _elevation ? 'elevation' : 'plan'),
            label: Text(_elevation ? 'Share niche elevation DXF' : 'Share niche plan DXF')))),
          CadPlanPreview(key: ValueKey(_elevation), drawing: drawing),
          const Text('Nominal geometry only. No structure, weatherproofing, fittings, accessibility verification or cemetery approval.'),
        ],
      ],
    )));
  }
}
