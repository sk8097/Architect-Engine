import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/open_drain_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class OpenDrainCadScreen extends StatefulWidget {
  const OpenDrainCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<OpenDrainCadScreen> createState() => _OpenDrainCadScreenState();
}

class _OpenDrainCadScreenState extends State<OpenDrainCadScreen> {
  late final _result = OpenDrainCadGenerator().generate(widget.brief);
  _DrainSheet _sheet = _DrainSheet.plan;
  bool _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_open_drain_$sheet.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = switch (_sheet) {
      _DrainSheet.plan => _result.plan,
      _DrainSheet.section => _result.section,
      _DrainSheet.profile => _result.profile,
    };
    return Scaffold(appBar: AppBar(title: const Text('Surveyed open drain CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No open drain drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Reach ${_m(_result.lengthMm)} m · Grade ${_result.grade.toStringAsFixed(3)}% · Bank top width ${_m(_result.topWidthMm)} m'),
          Text('Reference area ${_result.referenceAreaM2.toStringAsFixed(3)} m² · Geometric freeboard ${_m(_result.freeboardMm)} m'),
          Wrap(spacing: 12, children: [
            for (final sheet in _DrainSheet.values)
              ChoiceChip(label: Text(sheet.label), selected: _sheet == sheet, onSelected: (_) => setState(() => _sheet = sheet)),
          ]),
          Text(_sheet == _DrainSheet.plan
              ? 'Orange: banks · Blue: bottom edges · Green: maintenance reserve · Grey: available corridor'
              : 'Orange: bank · Blue: invert · Teal: reference depth (not a predicted water level) · True scale'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _sheet.name),
            label: Text('Share ${_sheet.name} DXF')))),
          CadPlanPreview(key: ValueKey(_sheet), drawing: drawing),
          const Text('Geometry only. The section and profile do not establish hydraulic capacity, actual freeboard, excavation, bank stability, outlet safety or permits.'),
        ],
      ],
    )));
  }
}

enum _DrainSheet {
  plan('Projected plan'), section('Cross-section'), profile('Invert profile');
  const _DrainSheet(this.label);
  final String label;
}
