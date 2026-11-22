import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/finish_measurement.dart';
import '../models/project_model.dart';
import '../providers/project_provider.dart';
import '../services/finish_schedule.dart';

class FinishScheduleScreen extends StatefulWidget {
  const FinishScheduleScreen({super.key, required this.project});
  final ProjectModel project;

  @override
  State<FinishScheduleScreen> createState() => _FinishScheduleScreenState();
}

class _FinishScheduleScreenState extends State<FinishScheduleScreen> {
  late final _rows = [...widget.project.finishMeasurements];
  bool _busy = false;

  Future<void> _write(List<FinishMeasurement> rows) async {
    final provider = context.read<ProjectProvider>();
    setState(() => _busy = true);
    try {
      await provider.saveFinishMeasurements(widget.project.id, rows);
      if (mounted) setState(() => _rows..clear()..addAll(rows));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save finish measurements.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([int? index]) async {
    final row = await showDialog<FinishMeasurement>(context: context,
      builder: (_) => _FinishRowDialog(original: index == null ? null : _rows[index]));
    if (!mounted || row == null) return;
    final next = [..._rows];
    if (index == null) { next.add(row); } else { next[index] = row; }
    await _write(next);
  }

  Future<void> _remove(int index) async {
    final remove = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Remove finish measurement?'),
      content: Text(_rows[index].location),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
      ],
    ));
    if (mounted && remove == true) await _write([..._rows]..removeAt(index));
  }

  Future<void> _share(BuildContext buttonContext, String csv) async {
    final box = buttonContext.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    final name = widget.project.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    setState(() => _busy = true);
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(csv)), mimeType: 'text/csv')],
        fileNameOverrides: ['${name.isEmpty ? 'project' : name}_finish_schedule.csv'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not share the CSV.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _qty(double value) => value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) {
    final schedule = FinishSchedule(_rows);
    final csv = schedule.toCsv();
    return Scaffold(
      appBar: AppBar(title: const Text('Measured finish schedule')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.project.name, style: Theme.of(context).textTheme.titleLarge),
        const Text('Enter measured faces and linear runs. Deductions are per repeat. Enter one material code for each distinct specification.'),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: [
          FilledButton.icon(onPressed: _busy || _rows.length >= FinishMeasurement.maxRows ? null : () => _edit(),
            icon: const Icon(Icons.add), label: const Text('Add measurement')),
          if (csv != null) Builder(builder: (button) => OutlinedButton.icon(
            onPressed: _busy ? null : () => _share(button, csv), icon: const Icon(Icons.ios_share), label: const Text('Share finish CSV'))),
        ]),
        if (_rows.isEmpty) const ListTile(title: Text('No finishes measured yet')),
        for (var i = 0; i < _rows.length; i++) ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_rows[i].location),
          subtitle: Text('${FinishMeasurement.kinds[_rows[i].kind]} · ${_rows[i].material}\n'
              'Net ${_qty(_rows[i].net)} ${_rows[i].unit} · With waste ${_qty(_rows[i].allowance)} ${_rows[i].unit}'),
          onTap: _busy ? null : () => _edit(i),
          trailing: IconButton(tooltip: 'Remove measurement', onPressed: _busy ? null : () => _remove(i), icon: const Icon(Icons.delete_outline)),
        ),
        if (schedule.totals.isNotEmpty) ...[
          const Divider(),
          Text('Material totals', style: Theme.of(context).textTheme.titleMedium),
          for (final total in schedule.totals) ListTile(contentPadding: EdgeInsets.zero, title: Text(total.material),
            subtitle: Text('Net ${_qty(total.net)} ${total.unit} · With waste ${_qty(total.allowance)} ${total.unit}')),
        ],
        const SizedBox(height: 12),
        const Text('Quantity takeoff only. No automatic surface extraction, layout, product specification, package rounding or compliance checks.'),
      ])),
    );
  }
}

class _FinishRowDialog extends StatefulWidget {
  const _FinishRowDialog({this.original});
  final FinishMeasurement? original;

  @override
  State<_FinishRowDialog> createState() => _FinishRowDialogState();
}

class _FinishRowDialogState extends State<_FinishRowDialog> {
  late String _kind = widget.original?.kind ?? 'floor';
  late final _location = TextEditingController(text: widget.original?.location);
  late final _material = TextEditingController(text: widget.original?.material);
  late final _length = TextEditingController(text: widget.original?.length.toString());
  late final _width = TextEditingController(text: widget.original?.width?.toString());
  late final _deduction = TextEditingController(text: (widget.original?.deduction ?? 0).toString());
  late final _count = TextEditingController(text: (widget.original?.count ?? 1).toString());
  late final _waste = TextEditingController(text: (widget.original?.waste ?? 0).toString());
  String? _error;

  @override
  void dispose() {
    for (final controller in [_location, _material, _length, _width, _deduction, _count, _waste]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _apply() {
    double number(TextEditingController field) => double.tryParse(field.text.trim()) ?? double.nan;
    final row = FinishMeasurement(location: _location.text.trim(), kind: _kind, material: _material.text.trim(),
      length: number(_length), width: FinishMeasurement.linear(_kind) ? null : number(_width),
      deduction: number(_deduction), count: int.tryParse(_count.text.trim()) ?? 0, waste: number(_waste));
    final issue = row.issue;
    if (issue == null) { Navigator.of(context).pop(row); } else { setState(() => _error = issue); }
  }

  TextField _field(TextEditingController controller, String label, {bool numeric = false, bool integer = false}) =>
      TextField(controller: controller, keyboardType: numeric
        ? TextInputType.numberWithOptions(decimal: !integer) : TextInputType.text,
        decoration: InputDecoration(labelText: label));

  @override
  Widget build(BuildContext context) {
    final linear = FinishMeasurement.linear(_kind);
    return AlertDialog(
      title: Text(widget.original == null ? 'Add finish measurement' : 'Edit finish measurement'),
      scrollable: true,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<String>(initialValue: _kind, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Surface or run'),
          items: [for (final kind in FinishMeasurement.kinds.entries)
            DropdownMenuItem(value: kind.key, child: Text(kind.value, overflow: TextOverflow.ellipsis))],
          onChanged: (value) { if (value != null) setState(() => _kind = value); }),
        _field(_location, 'Location / reference'),
        _field(_material, 'Material code / specification'),
        _field(_length, 'Measured length (m)', numeric: true),
        if (!linear) _field(_width, 'Measured width or height (m)', numeric: true),
        _field(_deduction, 'Deduction per repeat (${linear ? 'm' : 'm²'})', numeric: true),
        _field(_count, 'Identical repeats', numeric: true, integer: true),
        _field(_waste, 'Waste (%)', numeric: true),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _apply, child: const Text('Save measurement'))],
    );
  }
}
