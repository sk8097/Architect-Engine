import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/concept_zoning_generator.dart';
import '../services/floor_plan_cad.dart';
import 'automatic_floor_plan_screen.dart';

class ConceptZoningScreen extends StatefulWidget {
  const ConceptZoningScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<ConceptZoningScreen> createState() => _ConceptZoningScreenState();
}

class _ConceptZoningScreenState extends State<ConceptZoningScreen> {
  late final _result = ConceptZoningGenerator().generate(widget.brief, widthFt: widget.widthFt,
    depthFt: widget.depthFt, facing: widget.facing);
  late final _drawings = _result.sheets.map(FloorPlanCad.fromZoning).toList(growable: false);
  var _selected = 0;
  var _sharing = false;

  Future<void> _share(BuildContext button, {required bool all}) async {
    if (_sharing || _drawings.isEmpty) return;
    final box = button.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    setState(() => _sharing = true);
    try {
      final name = widget.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final drawing = all ? FloorPlanCad.combined(_drawings) : _drawings[_selected];
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name}_zoning_${all ? 'all' : _selected + 1}.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not share DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheet = _result.sheets.isEmpty ? null : _result.sheets[_selected];
    String sqft(int area) => '${(area / (304.8 * 304.8)).toStringAsFixed(0)} sqft';
    return Scaffold(appBar: AppBar(title: const Text('Concept zoning CAD')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (sheet == null) ...[
          Text('No zoning drawing generated', style: theme.textTheme.titleLarge),
          const Text('Your brief was saved. Edit the project and save it again to retry.'),
          for (final issue in _result.issues) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text(_result.focus),
          Text('Allocated ${sqft(sheet.allocated)} · Envelope ${sqft(sheet.envelope.area)}'),
          const Text('Concept only. Not a room layout, egress check, technical drawing or construction approval.'),
          const SizedBox(height: 10),
          if (_drawings.length > 1) DropdownButtonFormField<int>(initialValue: _selected, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Drawing level'),
            items: [for (var i = 0; i < _drawings.length; i++) DropdownMenuItem(value: i,
              child: Text(_result.sheets[i].title, overflow: TextOverflow.ellipsis))],
            onChanged: (value) { if (value != null) setState(() => _selected = value); }),
          const SizedBox(height: 10),
          CadPlanPreview(drawing: _drawings[_selected]),
          Wrap(spacing: 8, children: [
            Builder(builder: (button) => FilledButton.icon(icon: const Icon(Icons.ios_share),
              onPressed: _sharing ? null : () => _share(button, all: false), label: const Text('Share zoning DXF'))),
            if (_drawings.length > 1) Builder(builder: (button) => OutlinedButton(
              onPressed: _sharing ? null : () => _share(button, all: true), child: const Text('Share all sheets'))),
          ]),
          if (sheet.corridor) const Text('Straight corridor envelope only: no surveyed bends, levels, alignment or road design.')
          else const Text('Rectangle allocation only: no partitions, doors, services or specialist workflow verified. Optional preferences are not guaranteed.'),
          for (final zone in sheet.zones) ListTile(dense: true, title: Text(zone.name),
            subtitle: Text('${zone.bounds.width / 1000} × ${zone.bounds.depth / 1000} m')),
        ],
      ])),
    );
  }
}
