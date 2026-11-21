import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/t_junction_cad_generator.dart';
import '../services/cross_junction_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class TJunctionCadScreen extends StatefulWidget {
  const TJunctionCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<TJunctionCadScreen> createState() => _TJunctionCadScreenState();
}

class _TJunctionCadScreenState extends State<TJunctionCadScreen> {
  late final _cross = CrossJunctionCadGenerator.requested(widget.brief);
  late final _result = _cross ? CrossJunctionCadGenerator().generate(widget.brief) : TJunctionCadGenerator().generate(widget.brief);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad cad) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(cad.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_${_cross ? 'four_arm_junction' : 't_junction'}.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cad = _result.drawing;
    return Scaffold(appBar: AppBar(title: Text(_cross ? 'Survey four-arm intersection CAD' : 'Survey T-junction CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (cad == null) ...[
          const Text('No junction drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          const Text('Black: carriageway edges · Green: curb-return arcs · Grey: right-of-way · Blue: centreline reference · Purple: supplied controls.'),
          CadPlanPreview(drawing: cad),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, cad), label: const Text('Share junction DXF')))),
          const Text('Projected coordinates in millimetres. Measured concept only; rights of way are not verified property boundaries.'),
          const Text('No lanes, road markings, swept paths, signs, sight distances, traffic safety, levels or drainage designed.'),
        ],
      ],
    )));
  }
}
