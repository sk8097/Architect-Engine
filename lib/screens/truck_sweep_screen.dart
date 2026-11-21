import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/truck_sweep_generator.dart';
import 'automatic_floor_plan_screen.dart';

class TruckSweepScreen extends StatefulWidget {
  const TruckSweepScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<TruckSweepScreen> createState() => _TruckSweepScreenState();
}

class _TruckSweepScreenState extends State<TruckSweepScreen> {
  late final _result = TruckSweepGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_truck_sweep.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Rigid truck swept-path CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No swept path exported'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Rear-axle path: ${(_result.axleTravelMm / 1000).toStringAsFixed(3)} m'),
          const Text('Blue: rear-axle path · Purple: buffered corner traces · Black: truck poses · Red: fixed obstacles · Orange: dock guide.'),
          CadPlanPreview(drawing: drawing),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing), label: const Text('Share swept-path DXF')))),
          const Text('Only the supplied 2D rigid body, circular radius, boundaries and obstacles are checked. No steering transitions, gradients, vehicle access, staffing, dock height or operational approval is assessed.'),
        ],
      ],
    )));
  }
}
