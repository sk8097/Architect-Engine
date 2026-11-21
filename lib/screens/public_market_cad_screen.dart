import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/public_market_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class PublicMarketCadScreen extends StatefulWidget {
  const PublicMarketCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name;
  final double widthFt, depthFt;
  final ProjectBrief brief;
  final String facing;

  @override
  State<PublicMarketCadScreen> createState() => _PublicMarketCadScreenState();
}

class _PublicMarketCadScreenState extends State<PublicMarketCadScreen> {
  late final _result = PublicMarketCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_public_market.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(int mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Open-air public market CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No market layout generated'),
          const Text('Your brief was saved. Edit the dimensions to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('${_result.stalls} stalls · Market envelope ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m'),
          Text('Stalls ${_result.stallAreaM2.toStringAsFixed(3)} m² · Internal circulation ${_result.circulationM2.toStringAsFixed(3)} m²'),
          const Text('Blue: stalls and openings · Green: circulation perimeter · Purple: approach from frontage.'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing), label: const Text('Share market plan DXF')))),
          CadPlanPreview(drawing: drawing),
          const Text('Concept only. Does not verify occupancy, emergency egress, accessibility, sanitation, stall structures or vehicle access.'),
        ],
      ],
    )));
  }
}
