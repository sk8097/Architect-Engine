import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/project_scenarios.dart';
import '../data/project_type_cad_coverage.dart';
import '../data/project_taxonomy.dart';
import 'project_wizard_screen.dart';
import 'tower_planner_screen.dart';

class ScenarioLibraryScreen extends StatefulWidget {
  const ScenarioLibraryScreen({super.key});

  @override
  State<ScenarioLibraryScreen> createState() => _ScenarioLibraryScreenState();
}

class _ScenarioLibraryScreenState extends State<ScenarioLibraryScreen> {
  static final _entries = [
    for (final scenario in projectScenarios) ...[
      _ScenarioEntry(scenario),
      for (final variant in libraryVariants(scenario)) _ScenarioEntry(scenario, variant),
    ],
  ];

  String _query = '', _category = '', _status = '';

  void _showCoverage(_ScenarioEntry entry) {
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: Text(entry.scenario.type.label),
      content: SingleChildScrollView(child: Text([
        entry.scenario.path,
        '',
        if (entry.isHighRise) 'High-rise concept planner.' else ...[
          if (entry.coverage.zoning) 'Shared measured concept zoning is available.',
          if (entry.coverage.offersEnclosed) 'Shared enclosed CAD is offered for eligible single-storey new layouts with measured rooms.',
          if (entry.scenario.generator != null) 'Registered low-rise house CAD for supported floor and parking inputs.',
          if (!entry.coverage.hasDedicatedRoute) 'No dedicated CAD route is listed for this type.',
          for (final option in entry.specialists) '• ${option.label}',
          if (entry.specialists.isNotEmpty) 'Specialist choices are listed by type. Configuration, fit and measured inputs can still block export.',
        ],
        '',
        'After saving, open Measured finish schedule from the project menu.',
      ].join('\n'))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  Future<void> _shareCoverage(BuildContext button) async {
    final box = button.findRenderObject();
    final origin = box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
    try {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode(projectTypeCadCoverageCsv())), mimeType: 'text/csv')],
        fileNameOverrides: ['project_type_cad_coverage.csv'], sharePositionOrigin: origin);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not share the coverage CSV.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _query.toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final matches = _entries.where((entry) =>
      (_category.isEmpty || entry.scenario.category.id == _category) &&
      (_status.isEmpty || entry.status == _status) &&
      tokens.every(entry.searchText.contains),
    ).toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Scenario Library'), actions: [
        Builder(builder: (button) => IconButton(tooltip: 'Share type coverage CSV', icon: const Icon(Icons.ios_share),
          onPressed: () => _shareCoverage(button))),
      ]),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Search scenarios', prefixIcon: Icon(Icons.search)),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All categories')),
                      for (final category in projectTaxonomy)
                        DropdownMenuItem(value: category.id, child: Text(category.label, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (value) => setState(() => _category = value ?? ''),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Generation status'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All statuses')),
                      DropdownMenuItem(value: 'CAD supported', child: Text('CAD supported')),
                      DropdownMenuItem(value: 'Input needed', child: Text('Input needed')),
                      DropdownMenuItem(value: 'Zoning CAD', child: Text('Zoning CAD')),
                      DropdownMenuItem(value: 'Brief only', child: Text('Brief only')),
                      DropdownMenuItem(value: 'Specialist options', child: Text('Specialist options')),
                      DropdownMenuItem(value: 'High-rise CAD', child: Text('High-rise CAD')),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? ''),
                  ),
                  const SizedBox(height: 10),
                  Text('${matches.map((entry) => entry.coverage.id).toSet().length} types · ${matches.length} scenarios'),
                  Text('${projectTypeCadCoverage.values.where((entry) => !entry.hasDedicatedRoute).length} catalogue types have no dedicated CAD route'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: matches.isEmpty
                ? const Center(child: Text('No scenarios match these filters.'))
                : ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final entry = matches[index];
                      return ListTile(
                        key: ValueKey(entry.variant?.id ?? entry.scenario.id),
                        title: Text(entry.scenario.label),
                        subtitle: Text([entry.scenario.path, if (entry.variant != null) entry.variant!.label, entry.status].join('\n')),
                        trailing: IconButton(
                          tooltip: 'View CAD coverage', icon: const Icon(Icons.info_outline),
                          onPressed: () => _showCoverage(entry),
                        ),
                        onTap: () {
                          if (entry.isHighRise) {
                            Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const TowerPlannerScreen()));
                          } else {
                            ProjectWizardScreen.open(context, scenario: entry.scenario, variant: entry.variant);
                          }
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioEntry {
  _ScenarioEntry(this.scenario, [this.variant]);
  final ProjectScenario scenario;
  final ProjectScenarioVariant? variant;

  late final coverage = projectTypeCadCoverage['${scenario.category.id}/${scenario.group.id}/${scenario.type.id}']!;
  bool get isHighRise => coverage.highRise;
  List<TaxonomyChoice> get specialists => coverage.specialists;
  String get status => isHighRise ? 'High-rise CAD'
    : variant?.generator != null ? 'CAD supported'
    : variant == null && scenario.generator != null ? 'Input needed'
    : specialists.isNotEmpty ? 'Specialist options' : coverage.zoning ? 'Zoning CAD' : 'Brief only';
  late final searchText = '${scenario.label} ${scenario.path} ${variant?.label ?? ''} $status'.toLowerCase();
}
