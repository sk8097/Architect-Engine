import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/rail_platform_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class RailPlatformCadScreen extends StatefulWidget {
  const RailPlatformCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<RailPlatformCadScreen> createState() => _RailPlatformCadScreenState();
}

class _RailPlatformCadScreenState extends State<RailPlatformCadScreen> {
  late final _result = RailPlatformCadGenerator().generate(widget.brief);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_rail_platform_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Surveyed rail platform CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No rail platform drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Platform ${_m(_result.lengthMm)} m long · Static offset ${_m(_result.offsetMm)} m · Clear band ${_m(_result.walkMm)} m'),
          Text('Edge minus rail: ${_m(_result.minRiseMm)} to ${_m(_result.maxRiseMm)} m · Maximum edge grade ${_result.maxGrade.toStringAsFixed(3)}%'),
          Text('Section at Ch ${_m(_result.cutMm)} m, where the signed edge-minus-rail difference is smallest.'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Platform plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Transverse section'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          Text(_section
            ? 'Blue: outer reserves · Green: clear band · Grey: rail reference · True scale'
            : 'Blue: platform edges · Green: clear band boundaries · Orange: section cut'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share platform section DXF' : 'Share platform plan DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Static reference geometry only. No train swept envelope, boarding gap, track gauge or cant, drainage, structure, tactile design or rail approval.'),
        ],
      ],
    )));
  }
}
