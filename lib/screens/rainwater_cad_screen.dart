import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/rainwater_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class RainwaterCadScreen extends StatefulWidget {
  const RainwaterCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final double widthFt, depthFt;
  final ProjectBrief brief;

  @override
  State<RainwaterCadScreen> createState() => _RainwaterCadScreenState();
}

class _RainwaterCadScreenState extends State<RainwaterCadScreen> {
  late final _result = RainwaterCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_rainwater.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _l(double value) => value.toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Roof rainwater harvesting CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No rainwater layout generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Roof ${_l(_result.roofM2)} m² · Estimated runoff ${_l(_result.runoffL)} L'),
          Text('First flush ${_l(_result.divertedL)} L · Net event water ${_l(_result.availableL)} L'),
          Text('Usable capacity ${_l(_result.capacityL)} L'),
          Text('Starting empty: stored ${_l(_result.storedL)} L · Excess ${_l(_result.excessL)} L'),
          const Text('Orange: horizontal roof catchment · Blue/teal: tank outlines · Green: clear service envelope.'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing), label: const Text('Share rainwater plan DXF')))),
          CadPlanPreview(drawing: drawing),
          const Text('One event estimate with tanks starting empty. Excess water is a volume only, not an overflow design. No gutters, pipes, water quality, seasonal supply or structural checks.'),
        ],
      ],
    )));
  }
}
