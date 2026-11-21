import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_model.dart';
import '../models/tower_brief.dart';
import '../providers/project_provider.dart';
import '../services/floor_plan_cad.dart';
import '../services/tower_plan_generator.dart';
import 'automatic_floor_plan_screen.dart';

class TowerPlannerScreen extends StatefulWidget {
  const TowerPlannerScreen({super.key, this.existing});
  final ProjectModel? existing;

  @override
  State<TowerPlannerScreen> createState() => _TowerPlannerScreenState();
}

class _TowerPlannerScreenState extends State<TowerPlannerScreen> {
  final _form = GlobalKey<FormState>();
  final _values = <String, String>{};
  final _stairs = <TowerSpace>[], _lifts = <TowerSpace>[], _shafts = <TowerSpace>[];
  final _groups = <TowerFloorGroup>[];
  String? _frontage, _error;
  int _step = 0;
  bool _busy = false;

  static const dimensions = <String, String>{
    'plotWidth': 'Plot width (E-W)', 'plotDepth': 'Plot depth (N-S)',
    'plateWidth': 'Ground plate width (E-W)', 'plateDepth': 'Ground plate depth (N-S)',
    'westOffset': 'Offset from west plot edge', 'southOffset': 'Offset from south plot edge',
    'wall': 'Wall thickness', 'corridor': 'Clear corridor width', 'door': 'Clear door width',
  };

  @override
  void initState() {
    super.initState();
    final project = widget.existing;
    final tower = project?.tower;
    if (project == null || tower == null) return;
    final map = tower.toMap();
    _values.addAll({'name': project.name, 'floors': '${tower.floors}', 'basis': tower.basis,
      for (final key in dimensions.keys) key: _metric(map[key] as int)});
    _frontage = tower.frontage;
    _stairs.addAll(tower.stairs); _lifts.addAll(tower.lifts); _shafts.addAll(tower.shafts);
    _groups.addAll(tower.groups);
  }

  Widget _text(String key, String label, {bool dimension = false, bool zero = false, bool floors = false}) => TextFormField(
    key: ValueKey('tower_$key'), initialValue: _values[key],
    decoration: InputDecoration(labelText: '$label${dimension ? ' (m)' : ''}'),
    keyboardType: dimension ? const TextInputType.numberWithOptions(decimal: true) : floors ? TextInputType.number : TextInputType.text,
    onChanged: (value) => _values[key] = value,
    validator: dimension ? (value) => _dimensionError(value, zero: zero) : floors
      ? (value) => _whole(value, minimum: 2) : _required,
  );

  int _mm(String key) => _readMm(_values[key])!;

  void _next() {
    if (_form.currentState?.validate() != true) return;
    if (_step == 0 && (_mm('westOffset') + _mm('plateWidth') > _mm('plotWidth') ||
        _mm('southOffset') + _mm('plateDepth') > _mm('plotDepth'))) {
      setState(() => _error = 'The entered plate does not fit inside the plot at these offsets.');
      return;
    }
    if (_step == 1 && (_stairs.isEmpty || _lifts.isEmpty || _shafts.isEmpty)) {
      setState(() => _error = 'Add at least one stair, lift and shaft reserve.');
      return;
    }
    setState(() { _step++; _error = null; });
  }

  Future<void> _generate() async {
    if (_busy || _form.currentState?.validate() != true) return;
    final brief = TowerBrief(floors: int.parse(_values['floors']!),
      plotWidth: _mm('plotWidth'), plotDepth: _mm('plotDepth'), plateWidth: _mm('plateWidth'), plateDepth: _mm('plateDepth'),
      westOffset: _mm('westOffset'), southOffset: _mm('southOffset'), frontage: _frontage!,
      wall: _mm('wall'), corridor: _mm('corridor'), door: _mm('door'), basis: _values['basis']!.trim(),
      stairs: _stairs, lifts: _lifts, shafts: _shafts, groups: _groups);
    final result = TowerPlanGenerator().generate(brief);
    final provider = context.read<ProjectProvider>();
    final name = _values['name']!.trim();
    final width = brief.plotWidth / 304.8, depth = brief.plotDepth / 304.8;
    final floors = '${brief.floors} levels (incl. ground)';
    setState(() { _busy = true; _error = null; });
    try {
      if (widget.existing == null) {
        await provider.addProject(name: name, length: depth, width: width, bhk: '', floors: floors,
          facing: brief.frontage, tower: brief);
      } else {
        await provider.updateProject(id: widget.existing!.id, name: name, length: depth, width: width, bhk: '',
          floors: floors, facing: brief.frontage, tower: brief);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(builder: (_) =>
        TowerPlanScreen(projectName: name, brief: brief, generated: result)));
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'Could not save this project. Please try again.'; });
    }
  }

  Future<void> _editCore(List<TowerSpace> list, String kind, [int? index]) async {
    if (index == null && _stairs.length + _lifts.length + _shafts.length >= TowerPlanGenerator.maxCoreSpaces) return;
    final space = await _spaceDialog(context, index == null ? null : list[index], kind: '$kind reserve');
    if (!mounted || space == null) return;
    setState(() { if (index == null) { list.add(space); } else { list[index] = space; } _error = null; });
  }

  Widget _coreList(String label, List<TowerSpace> list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    for (var i = 0; i < list.length; i++) ListTile(contentPadding: EdgeInsets.zero, dense: true,
      title: Text('$label: ${list[i].name}'), subtitle: Text(_spaceSize(list[i])),
      onTap: () => _editCore(list, label, i), trailing: IconButton(icon: const Icon(Icons.close),
        tooltip: 'Remove reserve', onPressed: () => setState(() => list.removeAt(i)))),
    OutlinedButton.icon(icon: const Icon(Icons.add), label: Text('Add ${label.toLowerCase()} reserve'),
      onPressed: _stairs.length + _lifts.length + _shafts.length >= TowerPlanGenerator.maxCoreSpaces ? null : () => _editCore(list, label)),
  ]);

  Future<void> _editGroup([int? index]) async {
    final initial = index == null ? null : _groups[index];
    final start = _groups.fold(1, (n, group) => group.last >= n ? group.last + 1 : n);
    final prior = _groups.where((group)=>group.last==start-1).firstOrNull;
    final result = await Navigator.of(context).push<TowerFloorGroup>(MaterialPageRoute(builder: (_) =>
      _GroupEditor(initial: initial, nextLevel: start, floors: int.parse(_values['floors']!),
        inheritedInsets: prior?.insets ?? const TowerPlateInsets())));
    if (!mounted || result == null) return;
    setState(() { if (index == null) { _groups.add(result); } else { _groups[index] = result; } _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Site and floor plate', 'Shared stairs, lifts and shafts', 'Floor groups'];
    final theme = Theme.of(context);
    return Scaffold(appBar: AppBar(title: const Text('High-rise planner'), leading: BackButton(onPressed: _busy ? () {} : () {
      if (_step == 0) { Navigator.of(context).pop(); } else { setState(() { _step--; _error = null; }); }
    })), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 660),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Step ${_step + 1} of 3', style: theme.textTheme.labelLarge),
          Text(titles[_step], style: theme.textTheme.headlineSmall),
        ])),
        Expanded(child: Form(key: _form, child: SingleChildScrollView(key: ValueKey(_step), padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_step == 0) ...[
            const Text('Level 1 is ground. Upper groups may use the same plate or step in from its edges.'),
            _text('name', 'Project name'), _text('floors', 'Total levels including ground', floors: true),
            for (final key in dimensions.keys.take(6)) _text(key, dimensions[key]!, dimension: true, zero: key.endsWith('Offset')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _frontage,
              decoration: const InputDecoration(labelText: 'Ground entrance side'),
              items: const ['North', 'East', 'South', 'West'].map((side) => DropdownMenuItem(value: side, child: Text(side))).toList(),
              validator: _required, onChanged: (side) => _frontage = side),
          ],
          if (_step == 1) ...[
            const Text('Enter supplied dimensions. The planner reserves exactly the cores you add. If any plate steps inward, their clear widths are held exact and aligned across all levels. No code sizing.'),
            _text('basis', 'Source of dimensions (drawing / study reference)'),
            for (final key in dimensions.keys.skip(6)) _text(key, dimensions[key]!, dimension: true),
            const SizedBox(height: 12),
            _coreList('Stair', _stairs), _coreList('Lift', _lifts), _coreList('Shaft', _shafts),
          ],
          if (_step == 2) ...[
            Text('Cover levels 1 to ${_values['floors']} with no gaps or overlaps. Use one group for floors with the same layout. Level 1 gets its own entrance sheet.'),
            const SizedBox(height: 8),
            Text('Gross ground plate: ${_sqft(_mm('plateWidth') * _mm('plateDepth'))} sqft'),
            const Text('Split ground/podium and upper levels into separate groups to enter different rectangular footprints.'),
            for (var i = 0; i < _groups.length; i++) ListTile(contentPadding: EdgeInsets.zero,
              title: Text(_groups[i].name), subtitle: Text('${_groups[i].range} • ${_groups[i].spaces.length} spaces • ${_groups[i].insets.isZero?'Ground plate':'Inset plate'}'),
              onTap: () => _editGroup(i), trailing: IconButton(icon: const Icon(Icons.close), tooltip: 'Remove group',
                onPressed: () => setState(() => _groups.removeAt(i)))),
            OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('Add floor group'),
              onPressed: _groups.length >= int.parse(_values['floors']!) ? null : () => _editGroup()),
          ],
        ])))),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          FilledButton(onPressed: _busy ? null : (_step == 2 ? _generate : _next),
            child: Text(_busy ? 'Saving…' : _step == 2 ? 'Save & generate CAD' : 'Continue')),
        ])),
      ]),
    ))));
  }
}

class _GroupEditor extends StatefulWidget {
  const _GroupEditor({required this.initial, required this.nextLevel, required this.floors,required this.inheritedInsets});
  final TowerFloorGroup? initial;
  final int nextLevel, floors;
  final TowerPlateInsets inheritedInsets;
  @override
  State<_GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<_GroupEditor> {
  final _form = GlobalKey<FormState>();
  late String _name = widget.initial?.name ?? '';
  late String _first = '${widget.initial?.first ?? (widget.nextLevel > widget.floors ? 1 : widget.nextLevel)}';
  late String _last = widget.initial == null ? '' : '${widget.initial!.last}';
  late final _spaces = <TowerSpace>[...?widget.initial?.spaces];
  late final _originalInsets = widget.initial?.insets ?? widget.inheritedInsets;
  late bool _useInsets = !_originalInsets.isZero;
  late final _insets = _originalInsets.toMap().map((key,value)=>MapEntry(key,_metric(value)));
  String? _error;

  Future<void> _edit([int? index]) async {
    final result = await _spaceDialog(context, index == null ? null : _spaces[index]);
    if (!mounted || result == null) return;
    setState(() { if (index == null) { _spaces.add(result); } else { _spaces[index] = result; } _error = null; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Floor group')),
    body: SafeArea(child: Form(key: _form, child: SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(initialValue: _name, decoration: const InputDecoration(labelText: 'Group name (e.g. Offices)'),
        validator: _required, onChanged: (value) => _name = value),
      TextFormField(initialValue: _first, decoration: const InputDecoration(labelText: 'First level'), keyboardType: TextInputType.number,
        validator: (value) => _whole(value, maximum: widget.floors), onChanged: (value) => _first = value),
      TextFormField(initialValue: _last, decoration: const InputDecoration(labelText: 'Last level'), keyboardType: TextInputType.number,
        validator: (value) => _whole(value, maximum: widget.floors), onChanged: (value) => _last = value),
      const SizedBox(height: 12),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Inset plate for this group'),value:_useInsets,
        onChanged:(value)=>setState(()=>_useInsets=value)),
      if (_useInsets) ...[
        const Text('Measure inward from each edge of the ground plate, not from the previous floor. Enter zero on an unchanged side.'),
        for (final side in const {'west':'West','south':'South','east':'East','north':'North'}.entries)
          TextFormField(key:ValueKey('tower_inset_${side.key}'),initialValue:_insets[side.key],
            decoration:InputDecoration(labelText:'${side.value} inset from ground plate (m)'),
            keyboardType:const TextInputType.numberWithOptions(decimal:true),
            validator:(value)=>_dimensionError(value,zero:true),onChanged:(value)=>_insets[side.key]=value),
      ],
      const SizedBox(height:12),
      const Text('Add rooms or zones for one typical floor. Minimum width runs across the lane. Exact depth runs along the corridor.'),
      for (var i = 0; i < _spaces.length; i++) ListTile(contentPadding: EdgeInsets.zero,
        title: Text(_spaces[i].name), subtitle: Text(_spaceSize(_spaces[i])), onTap: () => _edit(i),
        trailing: IconButton(icon: const Icon(Icons.close), tooltip: 'Remove space', onPressed: () => setState(() => _spaces.removeAt(i)))),
      OutlinedButton.icon(icon: const Icon(Icons.add), label: const Text('Add room or zone'),
        onPressed: _spaces.length >= TowerPlanGenerator.maxSpaces ? null : () => _edit()),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      FilledButton(onPressed: () {
        if (_form.currentState?.validate() != true) return;
        if (int.parse(_first) > int.parse(_last) || _spaces.isEmpty) {
          setState(() => _error = 'Use an ordered level range and add at least one room or zone.'); return;
        }
        final insets = _useInsets ? TowerPlateInsets(west:_readMm(_insets['west'])!,south:_readMm(_insets['south'])!,
          east:_readMm(_insets['east'])!,north:_readMm(_insets['north'])!) : const TowerPlateInsets();
        Navigator.of(context).pop(TowerFloorGroup(_name.trim(), int.parse(_first), int.parse(_last), _spaces,insets:insets));
      }, child: const Text('Save floor group')),
    ])))),
  );
}

Future<TowerSpace?> _spaceDialog(BuildContext context, TowerSpace? initial, {String? kind}) {
  final form = GlobalKey<FormState>();
  var name = initial?.name ?? '';
  var width = initial == null ? '' : _metric(initial.width);
  var depth = initial == null ? '' : _metric(initial.depth);
  var window = initial?.window == null ? '' : _metric(initial!.window!);
  return showDialog<TowerSpace>(context: context, builder: (context) => AlertDialog(
    title: Text(kind ?? 'Room or zone'), scrollable: true,
    content: SizedBox(width: 400, child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(initialValue: name, decoration: const InputDecoration(labelText: 'Name'),
        validator: _required, onChanged: (value) => name = value),
      TextFormField(initialValue: width, decoration: const InputDecoration(labelText: 'Minimum clear width (m)'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _dimensionError,
        onChanged: (value) => width = value),
      TextFormField(initialValue: depth, decoration: const InputDecoration(labelText: 'Clear depth (m)'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _dimensionError,
        onChanged: (value) => depth = value),
      if (kind == null) TextFormField(initialValue: window, decoration: const InputDecoration(labelText: 'Exterior window width (m), optional'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => (value ?? '').trim().isEmpty ? null : _dimensionError(value), onChanged: (value) => window = value),
    ]))), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      FilledButton(onPressed: () {
        if (form.currentState?.validate() == true) Navigator.of(context).pop(
          TowerSpace(name.trim(), _readMm(width)!, _readMm(depth)!, window: _readMm(window)));
      }, child: const Text('Save space'))],
  ));
}

String? _required(String? value) => (value ?? '').trim().isEmpty ? 'Required.' : null;
String? _whole(String? value, {int minimum = 1, int maximum = TowerPlanGenerator.maxLevels}) {
  final n = int.tryParse(value ?? '');
  return n == null || n < minimum || n > maximum ? 'Enter $minimum to $maximum.' : null;
}
int? _readMm(String? value) {
  final n = double.tryParse(value ?? '');
  return n != null && n.isFinite && n >= 0 && n <= TowerPlanGenerator.maxDimension / 1000 ? (n * 1000).round() : null;
}
String? _dimensionError(String? value, {bool zero = false}) {
  final n = _readMm(value);
  return n == null || (!zero && n < 1) ? (zero ? 'Enter 0 to 300 m.' : 'Enter a positive length up to 300 m.') : null;
}
String _metric(int mm) => (mm / 1000).toString();
String _spaceSize(TowerSpace space) => '${_metric(space.width)} m min. width × ${_metric(space.depth)} m depth';
String _sqft(int squareMm) => (squareMm / (304.8 * 304.8)).toStringAsFixed(0);

class TowerPlanScreen extends StatefulWidget {
  const TowerPlanScreen({super.key, required this.projectName, required TowerBrief this.brief, this.generated})
    : title = 'High-rise CAD', note = null, areaSqft = null;
  const TowerPlanScreen.dwelling({super.key, required this.projectName, required TowerResult this.generated, required double this.areaSqft})
    : brief = null, title = 'G+1 house CAD', note =
      'Plan-view stairs and roof only. Verify stair sections, headroom, openings, handrails, parapet height, roof structure, drainage and local code before construction.';
  const TowerPlanScreen.stackedRetail({super.key,required this.projectName,required TowerResult this.generated,required double this.areaSqft})
    : brief=null,title='Shop below dwelling CAD',note=
      'Concept only. The private stair and divider show geometric separation, not rated construction. Verify stair section and headroom, fire/egress and accessibility, structure, acoustics and utilities separately.';
  const TowerPlanScreen.sharedCore({super.key, required this.projectName, required TowerResult this.generated, required double this.areaSqft})
    : brief = null, title = 'Shop below office CAD', note =
      'Concept only. Shaft is a sealed dimensional reserve; no lift, utility design, structural or fire rating is implied. Verify stairs, headroom, occupancy, fire exits and accessible access separately.';
  final String projectName, title;
  final String? note;
  final double? areaSqft;
  final TowerBrief? brief;
  final TowerResult? generated;

  @override
  State<TowerPlanScreen> createState() => _TowerPlanScreenState();
}

class _TowerPlanScreenState extends State<TowerPlanScreen> {
  late final _result = widget.generated ?? TowerPlanGenerator().generate(widget.brief!);
  final _drawings = <int, FloorPlanCad>{};
  var _selected = 0;
  var _sharing = false;

  FloorPlanCad _drawing(int index) => _drawings.putIfAbsent(index, () {
    final sheet = _result.sheets[index];
    return FloorPlanCad.fromPlan(sheet.plan, siteZones: sheet.siteZones);
  });

  Future<void> _share(BuildContext button, {required bool all}) async {
    if (_sharing) return;
    final box = button.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    setState(() => _sharing = true);
    try {
      final sheet = _result.sheets[_selected];
      final drawing = all ? FloorPlanCad.combined(Iterable.generate(_result.sheets.length, _drawing)) : _drawing(_selected);
      final safeName = widget.projectName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final suffix = all ? 'all_sheets' : sheet.range=='Roof terrace' ? 'roof_terrace' : 'levels_${sheet.first}-${sheet.last}';
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(ascii.encode(drawing.toDxf())),
        mimeType: 'application/dxf')], fileNameOverrides: ['${safeName}_$suffix.dxf'], sharePositionOrigin: origin);
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
    final drawing = sheet == null ? null : _drawing(_selected);
    return Scaffold(appBar: AppBar(title: Text(widget.title)), body: SafeArea(child: Center(child:
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 710), child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.projectName, style: theme.textTheme.headlineSmall),
        Text('${widget.brief?.floors ?? 2} levels · Plot ${widget.areaSqft?.toStringAsFixed(0) ?? _sqft(widget.brief!.plotWidth * widget.brief!.plotDepth)} sqft'),
        const SizedBox(height: 12),
        if (sheet == null) ...[
          const Text('No drawing generated. Edit the saved brief before exporting.'),
          ..._result.issues.map((issue) => ListTile(title: Text(issue), leading: const Icon(Icons.error_outline))),
        ] else ...[
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${sheet.range=='Roof terrace'?'Roof area':'Per floor'} · ${sheet.name}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 18, runSpacing: 8, children: [
              _metricTile('Available', sheet.available), _metricTile('Planned', sheet.planned),
              _metricTile('Unallocated', sheet.unallocated),
            ]),
            const SizedBox(height: 6),
            if (sheet.range=='Roof terrace')
              const Text('Planned includes the open deck, walk, stair enclosure and parapet.')
            else const Text('Planned includes shared core, circulation and walls.'),
            if (widget.brief!=null) Text('Plate: ${_metric(sheet.plan.footprint.width)} m E–W × ${_metric(sheet.plan.footprint.depth)} m N–S'),
          ]))),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(initialValue: _selected, isExpanded: true,
            decoration: InputDecoration(labelText: 'Floor groups (${_result.sheets.length} sheets)'),
            items: [for (var i = 0; i < _result.sheets.length; i++) DropdownMenuItem(value: i,
              child: Text('${_result.sheets[i].range} — ${_result.sheets[i].name}', overflow: TextOverflow.ellipsis))],
            onChanged: (index) { if (index != null) setState(() => _selected = index); }),
          const SizedBox(height: 12),
          Text('${sheet.range} · ${sheet.name}', style: theme.textTheme.titleLarge),
          const Text('Concept preview · Specialist review pending'),
          const SizedBox(height: 8),
          CadPlanPreview(plan: sheet.plan, drawing: drawing!),
          if (sheet.siteZones.any((zone)=>zone.layer=='GROUND_PLATE_REFERENCE'))
            const Text('Grey outline: ground plate reference. Upper footprint is inset; exposed roof areas are not planned.')
          else if (sheet.siteZones.any((zone)=>zone.layer=='PARKING_BAYS'))
            Text('${sheet.siteZones.where((zone) => zone.layer == 'PARKING_BAYS').length} open bays · '
              'Vehicle approach and separate pedestrian entrance walk. No vehicle swept-path, curb cut, slope or access approval verified.'),
          if (sheet.siteZones.any((zone)=>zone.layer=='SHARED_CORE_SHAFT'))
            const Text('Orange: shared approach. Green: common lobby. Purple: aligned shaft reserve.'),
          if (sheet.siteZones.any((zone)=>zone.layer=='MIXED_DIVIDER'))
            const Text('Orange: shop walk. Green: home walk. Purple: solid ground-floor divider. No internal shop-to-stair door.'),
          if (sheet.range=='Roof terrace')
            const Text('Green: the clear open deck. Purple: stair-head walk. The remaining roof is unallocated.'),
          for (final stair in sheet.plan.stairs)
            Text('${sheet.plan.stairs.length>1?(stair.roomId=='stair_1'?'Terrace: ':'Ground: '):''}${stair.up ? 'UP' : 'DOWN'}: ${stair.risers} risers × ${stair.riseMm.toStringAsFixed(1)} mm · '
              '${stair.goingMm} mm going · ${stair.floorHeightMm} mm floor-to-floor'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Builder(builder: (button) => FilledButton.icon(icon: const Icon(Icons.ios_share),
              onPressed: _sharing ? null : () => _share(button, all: false), label: const Text('Share selected DXF'))),
            Builder(builder: (button) => OutlinedButton(onPressed: _sharing ? null : () => _share(button, all: true),
              child: const Text('Share all sheets DXF'))),
          ]),
          const SizedBox(height: 8),
          Text(widget.note ?? 'Not for construction. Core reserves are not detailed stair or lift designs. No egress, structure, accessibility, setbacks or local-code compliance verified.'),
          if (widget.brief != null) Text('Supplied dimension reference: ${widget.brief!.basis}'),
          ExpansionTile(title: const Text('Floor schedule'), children: [
            for (final item in _result.sheets) ListTile(dense: true, title: Text(item.range), subtitle: Text(widget.brief==null?item.name:'${item.name} · ${_sqft(item.available)} sqft per floor')),
          ]),
        ],
      ])),
    )));
  }

  Widget _metricTile(String caption, int area) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('${_sqft(area)} sqft', style: Theme.of(context).textTheme.titleMedium), Text(caption),
  ]);
}
