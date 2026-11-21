import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/corridor_earthwork_generator.dart';
import 'automatic_floor_plan_screen.dart';

class CorridorEarthworkScreen extends StatefulWidget {
  const CorridorEarthworkScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<CorridorEarthworkScreen> createState() => _CorridorEarthworkScreenState();
}

class _CorridorEarthworkScreenState extends State<CorridorEarthworkScreen> {
  late final _result = CorridorEarthworkGenerator().generate(widget.brief);
  int _station = 0;
  bool _sharing = false;

  String _m(num mm) => _n(mm / 1000);
  String _n(num value) => value.toStringAsFixed(3);

  Future<void> _share(BuildContext context, {required String data, required String extension, required String mime}) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: mime)],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_earthwork.$extension'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not share the ${extension.toUpperCase()}.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cad = _result.drawing, sections = _result.sections;
    final selected = cad == null ? null : sections[_station];
    return Scaffold(appBar: AppBar(title: const Text('Corridor earthwork takeoff')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (cad == null || selected == null) ...[
          const Text('No earthwork takeoff generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Estimated cut ${_n(_result.totalCutM3)} m³ · fill ${_n(_result.totalFillM3)} m³'),
          Text('${sections.length} stations · average-end-area method'),
          const Text('Cut and fill are estimated separately between stations. No extrapolation, shrink/swell, stripping or alignment-curvature corrections.'),
          Builder(builder: (button) => Wrap(spacing: 10, children: [
            FilledButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, data: cad.toDxf(), extension: 'dxf', mime: 'application/dxf'), label: const Text('Share section-set DXF')),
            OutlinedButton.icon(icon: const Icon(Icons.ios_share), onPressed: _sharing ? null : () =>
              _share(button, data: _result.toCsv()!, extension: 'csv', mime: 'text/csv'), label: const Text('Share takeoff CSV')),
          ])),
          ExpansionTile(title: const Text('Interval quantities'), children: [
            for (final item in _result.intervals) ListTile(dense: true,
              title: Text('Ch ${_m(item.start.chainageMm)} to ${_m(item.end.chainageMm)} m · ${_n(item.lengthM)} m'),
              subtitle: Text('Cut ${_n(item.cutM3)} m³ · Fill ${_n(item.fillM3)} m³')),
          ]),
          const Text('Preview station'),
          DropdownButton<int>(value: _station, isExpanded: true,
            items: [for (var i = 0; i < sections.length; i++) DropdownMenuItem(value: i, child: Text('Ch ${_m(sections[i].chainageMm)} m'))],
            onChanged: (value) { if (value != null) setState(() => _station = value); }),
          Text('Section cut ${_n(selected.cutM2)} m² · Fill ${_n(selected.fillM2)} m²'),
          Text('Plot base ${_m(selected.datumMm)} m · ${selected.exaggeration}× vertical'),
          const Text('Orange: ground · Blue: design · Red: cut · Green: fill'),
          CadPlanPreview(key: ValueKey(_station), drawing: selected.drawing!),
        ],
      ],
    )));
  }
}
