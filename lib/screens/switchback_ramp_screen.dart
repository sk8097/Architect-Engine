import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/switchback_ramp_generator.dart';
import 'automatic_floor_plan_screen.dart';

class SwitchbackRampScreen extends StatefulWidget {
  const SwitchbackRampScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt, required this.facing});
  final String name, facing;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<SwitchbackRampScreen> createState() => _SwitchbackRampScreenState();
}

class _SwitchbackRampScreenState extends State<SwitchbackRampScreen> {
  late final _result = SwitchbackRampGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt, facing: widget.facing);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_switchback_$sheet.dxf'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Could not share the DXF.')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _m(num mm) => (mm / 1000).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final drawing = _profile ? _result.profile : _result.plan;
    return Scaffold(appBar: AppBar(title: const Text('Switchback ramp CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No ramp drawing generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Horizontal route length ${_m(_result.walkMm)} m · Total rise ${_m(_result.flights.last.toMm - _result.flights.first.fromMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Ramp plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Unfolded profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'True-scale unfolded profile along the marked centreline. X is horizontal station, Y is height above the lower landing.'
            : 'Blue: flights · Green: landings · Purple: route and clear turning squares · Grey: separator reserve.'),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share ramp profile DXF' : 'Share ramp plan DXF')))),
          const Text('Only the entered geometry and limits are checked. Terrain tie-ins, crossfall, rails, guards, construction and accessibility compliance are not verified.'),
          ExpansionTile(title: const Text('Flight schedule'), children: [
            for (final (i, flight) in _result.flights.indexed) ListTile(dense: true,
              title: Text('Flight ${i + 1} · ${flight.gradePercent.toStringAsFixed(3)}%'),
              subtitle: Text('Level ${_m(flight.fromMm)} to ${_m(flight.toMm)} m · Rise ${_m(flight.riseMm)} m')),
          ]),
        ],
      ],
    )));
  }
}
