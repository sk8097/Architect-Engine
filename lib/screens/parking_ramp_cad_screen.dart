import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/parking_ramp_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class ParkingRampCadScreen extends StatefulWidget {
  const ParkingRampCadScreen({super.key, required this.name, required this.brief,
    required this.widthFt, required this.depthFt});
  final String name;
  final ProjectBrief brief;
  final double widthFt, depthFt;

  @override
  State<ParkingRampCadScreen> createState() => _ParkingRampCadScreenState();
}

class _ParkingRampCadScreenState extends State<ParkingRampCadScreen> {
  late final _result = ParkingRampCadGenerator().generate(widget.brief, widthFt: widget.widthFt, depthFt: widget.depthFt);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_parking_ramp_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Parking ramp CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No parking ramp drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Main grade ${_result.grade.toStringAsFixed(3)}% · Transition grade ${_result.change.toStringAsFixed(3)}% · Breaks ${_result.change.toStringAsFixed(3)} percentage points'),
          Text('Minimum headroom ${_m(_result.headMm)} m at Ch ${_m(_result.stationMm)} m'),
          Text('Full envelope ${_m(_result.widthMm)} × ${_m(_result.depthMm)} m'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Ramp plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Longitudinal profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'Blue: drive surface · Red: soffit · Green: minimum vertical headroom · True scale'
            : 'Blue: ramp envelope · Orange: grade breaks · Red: overhead interval · Teal: uphill direction'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share ramp profile DXF' : 'Share ramp plan DXF')))),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          const Text('Static geometry only. No vehicle breakover, swept height, reverse movement, crossfall, drainage, guards or parking approval.'),
        ],
      ],
    )));
  }
}
