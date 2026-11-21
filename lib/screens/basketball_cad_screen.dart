import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/basketball_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class BasketballCadScreen extends StatefulWidget {
  const BasketballCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<BasketballCadScreen> createState() => _BasketballCadScreenState();
}

class _BasketballCadScreenState extends State<BasketballCadScreen> {
  late final _result = BasketballCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_basketball.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Outdoor basketball court CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No court drawing generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Marked court ${_m(_result.widthMm)} × ${_m(_result.lengthMm)} m'),
          Text('Clear run-off: ${_m(_result.sideMm)} m each side · ${_m(_result.endMm)} m each end'),
          const Text('Blue: court lines and keys · Purple: three-point lines · Green: run-off and approach · Red: basket centres.'),
          CadPlanPreview(drawing: drawing),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing), label: const Text('Share basketball court DXF')))),
          const Text('Measured marking centrelines only. No equipment or foundations, line thickness, drainage, accessibility, sports safety or rulebook certification are included.'),
        ],
      ],
    )));
  }
}
