import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/bus_layby_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class BusLaybyCadScreen extends StatefulWidget {
  const BusLaybyCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<BusLaybyCadScreen> createState() => _BusLaybyCadScreenState();
}

class _BusLaybyCadScreenState extends State<BusLaybyCadScreen> {
  late final _result = BusLaybyCadGenerator().generate(widget.brief);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_bus_layby.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Surveyed bus stop lay-by CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No bus lay-by drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.berths} berths · Ch ${_m(_result.startMm)} to ${_m(_result.endMm)} m on ${_m(_result.edgeMm)} m of road edge'),
          Text('Required roadside width ${_m(_result.requiredWidthMm)} m · Clear length at each shelter end ${_m(_result.shelterGapMm)} m'),
          const Text('Blue: lay-by edge · Teal: berths · Purple: boarding limits and travel arrow · Orange: shelter reserve · Green: rear path.'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing), label: const Text('Share lay-by plan DXF')))),
          CadPlanPreview(drawing: drawing),
          const Text('Concept only. No swept paths, traffic or sight-distance checks, kerb detail, drainage, accessibility or road safety approval.'),
        ],
      ],
    )));
  }
}
