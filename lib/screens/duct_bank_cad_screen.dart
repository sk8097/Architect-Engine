import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/duct_bank_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class DuctBankCadScreen extends StatefulWidget {
  const DuctBankCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<DuctBankCadScreen> createState() => _DuctBankCadScreenState();
}

class _DuctBankCadScreenState extends State<DuctBankCadScreen> {
  late final _result = DuctBankCadGenerator().generate(widget.brief);
  bool _profile = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_duct_bank_$sheet.dxf'], sharePositionOrigin: origin);
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
    return Scaffold(appBar: AppBar(title: const Text('Surveyed telecom duct bank CAD')), body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drawing == null) ...[
          const Text('No duct-bank drawings generated'),
          const Text('Your brief was saved. Edit it and save to retry.'),
          if (_result.issue case final issue?) ListTile(leading: const Icon(Icons.info_outline), title: Text(issue)),
        ] else ...[
          Text('Bank ${_m(_result.lengthMm)} m long × ${_m(_result.widthMm)} m wide · ${_result.crossings} recorded crossings'),
          Text('Minimum cover ${_m(_result.coverMm)} m at Ch ${_m(_result.coverStationMm)} m'),
          Text('Minimum crossing gap ${_m(_result.crossingGapMm)} m at ${_result.crossingId}'),
          Wrap(spacing: 12, children: [
            ChoiceChip(label: const Text('Duct-bank plan'), selected: !_profile, onSelected: (_) => setState(() => _profile = false)),
            ChoiceChip(label: const Text('Longitudinal profile'), selected: _profile, onSelected: (_) => setState(() => _profile = true)),
          ]),
          Text(_profile
            ? 'Blue: bank · Grey: ground · Orange: existing vertical envelopes · Green/teal: cover and gap · True scale'
            : 'Blue: bank outline · Grey: surveyed centreline · Orange: crossing stations'),
          Builder(builder: (button) => Align(alignment: Alignment.centerLeft, child: FilledButton.icon(icon: const Icon(Icons.ios_share),
            onPressed: _sharing ? null : () => _share(button, drawing, _profile ? 'profile' : 'plan'),
            label: Text(_profile ? 'Share duct-bank profile DXF' : 'Share duct-bank plan DXF')))),
          CadPlanPreview(key: ValueKey(_profile), drawing: drawing),
          const Text('Geometry only. No verification of unrecorded utilities, skew or clearance between surveyed stations, structural, pull or excavation safety.'),
        ],
      ],
    )));
  }
}
