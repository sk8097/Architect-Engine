import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/corridor_section_generator.dart';
import 'automatic_floor_plan_screen.dart';

class CorridorSectionScreen extends StatefulWidget {
  const CorridorSectionScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<CorridorSectionScreen> createState() => _CorridorSectionScreenState();
}

class _CorridorSectionScreenState extends State<CorridorSectionScreen> {
  late final _result = CorridorSectionGenerator().generate(widget.brief);
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad cad) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(cad.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_corridor_section.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final cad = _result.drawing;
    return Scaffold(appBar: AppBar(title: const Text('Corridor cross-section CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (cad == null) ...[
          const Text('No cross-section drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Chainage ${_m(_result.chainageMm)} m · looking toward increasing chainage'),
          Text('Cut ${_result.cutM2.toStringAsFixed(3)} m² · Fill ${_result.fillM2.toStringAsFixed(3)} m²'),
          Text('Plot base level ${_m(_result.datumMm)} m · ${_result.exaggeration}× vertical exaggeration (also in DXF)'),
          const Text('Orange: surveyed ground · Blue: proposed surface · Red: cut · Green: fill.'),
          CadPlanPreview(drawing: cad),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, cad), label: const Text('Share cross-section DXF')))),
          const Text('Areas are measured only between the supplied profiles within the proposed width. No earthwork volumes, tie-ins, material allowances or compliance checks are included.'),
          ExpansionTile(title: const Text('Proposed slopes (left to right)'), children: [
            for (final band in _result.bands) ListTile(dense: true,
              title: Text('${_m(band.from.offsetMm)} to ${_m(band.to.offsetMm)} m · ${band.crossfallPercent.toStringAsFixed(2)}%'),
              subtitle: Text('Level ${_m(band.from.levelMm)} to ${_m(band.to.levelMm)} m')),
          ]),
        ],
      ],
    )));
  }
}
