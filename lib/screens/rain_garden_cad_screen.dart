import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/rain_garden_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class RainGardenCadScreen extends StatefulWidget {
  const RainGardenCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<RainGardenCadScreen> createState() => _RainGardenCadScreenState();
}

class _RainGardenCadScreenState extends State<RainGardenCadScreen> {
  late final _result = RainGardenCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_rain_garden_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Rain garden CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No rain garden drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Full envelope ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m · Surface ponding ${_result.storageM3.toStringAsFixed(3)} m³'),
          Text('${_m(_result.pondMm)} m ponding depth · ${_m(_result.freeboardMm)} m freeboard'),
          Text('${_result.mediaM3.toStringAsFixed(3)} m³ planting media · ${_result.aggregateM3.toStringAsFixed(3)} m³ aggregate (gross)'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Rain garden plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Section A–A'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          Text(_section
            ? 'Blue: design water · Orange: planting media · Purple: aggregate · True scale'
            : 'Green: rim · Blue: design water outline · Teal: flat bed · Gold: cut A–A'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share rain garden section DXF' : 'Share rain garden plan DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Geometry only. No hydrology, infiltration, void storage, overflow, underdrain, earthwork or construction design.'),
        ],
      ],
    )));
  }
}
