import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_brief.dart';
import '../services/floor_plan_cad.dart';
import '../services/typology_bay_cad_generator.dart';
import 'automatic_floor_plan_screen.dart';

class TypologyBayCadScreen extends StatefulWidget {
  const TypologyBayCadScreen({super.key, required this.name, required this.brief});
  final String name;
  final ProjectBrief brief;

  @override
  State<TypologyBayCadScreen> createState() => _TypologyBayCadScreenState();
}

class _TypologyBayCadScreenState extends State<TypologyBayCadScreen> {
  late final _result = TypologyBayCadGenerator().generate(widget.brief);
  bool _section = false, _sharing = false;

  Future<void> _share(BuildContext context, FloorPlanCad drawing, String sheet) async {
    if (_sharing) return;
    final box = context.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())), mimeType: 'application/dxf')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_typology_bay_$sheet.dxf'],
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Could not share the DXF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = _result;
    final drawing = _section ? res.section : res.plan;
    final sheet = _section ? 'section' : 'plan';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name.isEmpty ? 'Project' : widget.name} — Parametric Bay CAD'),
        actions: [
          if (drawing != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share DXF',
              onPressed: _sharing ? null : () => _share(context, drawing, sheet),
            ),
        ],
      ),
      body: res.issue != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(res.issue!, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(label: const Text('Plan'), selected: !_section, onSelected: (_) => setState(() => _section = false)),
                      ChoiceChip(label: const Text('Section'), selected: _section, onSelected: (_) => setState(() => _section = true)),
                      Chip(label: Text('Footprint ${res.footprintArea.toStringAsFixed(1)} m²')),
                      Chip(label: Text('GFA ${res.grossFloorArea.toStringAsFixed(1)} m²')),
                      Chip(label: Text('Net ${res.netUsableArea.toStringAsFixed(1)} m²')),
                      Chip(label: Text('Coverage ${res.siteCoveragePct.toStringAsFixed(1)}%')),
                    ],
                  ),
                ),
                Expanded(
                  child: drawing == null
                      ? const SizedBox.shrink()
                      : InteractiveViewer(
                          minScale: 0.2,
                          maxScale: 8,
                          child: CustomPaint(
                            painter: FloorPlanCadPainter(drawing),
                            size: Size.infinite,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
