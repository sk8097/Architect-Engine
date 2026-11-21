import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/shelter_canopy_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class ShelterCanopyCadScreen extends StatefulWidget {
  const ShelterCanopyCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<ShelterCanopyCadScreen> createState() => _ShelterCanopyCadScreenState();
}

class _ShelterCanopyCadScreenState extends State<ShelterCanopyCadScreen> {
  late final _result = ShelterCanopyCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_shelter_canopy_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Passenger shelter canopy CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No shelter canopy drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Roof ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m · ${_result.posts} post envelopes'),
          Text('${_m(_result.walkMm)} m clear strip · ${_m(_result.walkHeadMm)} m minimum strip headroom · ${_m(_result.eaveMm)} m low eave'),
          Text('Roof fall ${_result.fallPct.toStringAsFixed(3)}% · Sloping plane area ${_result.roofM2.toStringAsFixed(3)} m²'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Canopy plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
            ChoiceChip(label: const Text('Transverse section'), selected: _section, onSelected: (_) => setState(() => _section = true)),
          ]),
          Text(_section
            ? 'Blue: roof envelope · Orange: posts · Green: submitted minimum headroom in the strip · True scale'
            : 'Blue: roof outline · Orange: posts · Green: clear walking strip'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _section ? 'section' : 'plan'),
            label: Text(_section ? 'Share canopy section DXF' : 'Share canopy plan DXF')))),
          CadPlanPreview(key: ValueKey(_section), drawing: drawing),
          const Text('Geometry only. No structure, wind/uplift, foundations, roof drainage, passenger loading or accessibility approval.'),
        ],
      ],
    )));
  }
}
