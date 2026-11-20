import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/project_taxonomy.dart';
import '../data/project_requirements.dart';
import '../data/project_scenarios.dart';
import '../models/project_brief.dart';
import '../models/project_model.dart';
import '../models/project_requirements_snapshot.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/requirement_fields.dart';
import '../services/automatic_floor_plan_generator.dart';
import 'automatic_floor_plan_screen.dart';

class ProjectWizardScreen extends StatefulWidget {
  const ProjectWizardScreen({super.key, this.existingProject, this.scenario, this.variant});

  final ProjectModel? existingProject;
  final ProjectScenario? scenario;
  final ProjectScenarioVariant? variant;

  static Future<void> open(BuildContext context, {ProjectModel? project,
    ProjectScenario? scenario, ProjectScenarioVariant? variant}) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => ProjectWizardScreen(existingProject: project, scenario: scenario, variant: variant),
    ));
  }

  @override
  State<ProjectWizardScreen> createState() => _ProjectWizardScreenState();
}

class _ProjectWizardScreenState extends State<ProjectWizardScreen> {
  static const _steps = [
    'Category', 'Subcategory', 'Project type', 'Configuration',
    'Space / room program', 'Project information', 'Site / plot / land',
    'Jurisdiction / rules', 'Facility requirements', 'Technical requirements',
    'Design preferences', 'Budget & deliverables', 'Review',
  ];
  static const _directions = [
    'North', 'North-East', 'East', 'South-East', 'South', 'South-West', 'West',
    'North-West', 'Not decided',
  ];

  final _sectionForms = List.generate(_steps.length, (_) => GlobalKey<FormState>());
  final _answers = <String, Object>{};
  final _facilityAnswers = <String, Object>{};
  final _spaceDetails = <String, Map<String, Object>>{};
  final _customSpaces = <String, String>{};
  String? _sectionError;
  final _spaceForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _width = TextEditingController();
  final _depth = TextEditingController();
  final _floors = TextEditingController();
  final _spaces = <String, String>{};
  TaxonomyCategory? _category;
  TaxonomyGroup? _group;
  TaxonomyChoice? _type;
  String? _configurationId;
  String? _actionId;
  String? _stageId;
  String? _shapeId;
  String? _facing;
  ProjectParking? _parking;
  String _typeQuery = '';
  int _step = 0;
  bool _saving = false;
  bool _unsupportedBrief = false;

  TaxonomyProgram get _program => taxonomyProgram(_group!, _type!);
  bool get _customInfrastructure => _category?.id == 'infrastructure' && _type?.id == 'custom';
  bool get _linearSite => _customInfrastructure
      ? _answers['custom_site_kind'] == 'linear'
      : _type != null && usesLinearSite(_category!.id, _group!.id, _type!.id);
  bool get _isRectangular => !_linearSite && (_shapeId == 'rectangular' || _shapeId == 'square');
  bool get _wantsParking => !_linearSite && _parking != null && _parking != ProjectParking.none;
  List<TaxonomyChoice> get _allSpaces => [
    ..._program.spaces,
    for (final item in _customSpaces.entries) TaxonomyChoice(item.key, item.value),
  ];
  List<RequirementField> get _facilitySchema => facilityFields(_group!, _type!);
  List<RequirementField> get _infoSchema => [
    ...projectInformationFields,
    if (_actionId != null && !const {'new_design', 'feasibility', 'concept_design', 'master_planning'}.contains(_actionId)) previousDesignField,
    if (_type?.id == 'custom') customTypeField,
    if (_customInfrastructure) customSiteKindField,
    if (_configurationId == 'custom') customConfigurationField,
  ];
  List<RequirementField> get _siteSchema => [
    ...siteCommonFields,
    if (_linearSite) ...alignmentFields else ...surveyedPlotFields,
  ];
  List<RequirementField> get _ruleSchema => _linearSite
      ? jurisdictionFields.take(5).toList() : jurisdictionFields;
  List<RequirementField> get _operationalSchema => [
    if (!_linearSite) ...buildingProgramFields,
    ...operationalFields,
    if (_wantsParking)
      ...parkingFields.where((field) => switch (field.id) {
        'cars' => _parking != ProjectParking.twoWheeler,
        'two_wheelers' => _parking != ProjectParking.car,
        _ => true,
      }),
  ];
  List<RequirementField> get _designSchema => _linearSite
      ? preferenceFields.where((f) => f.id == 'sustainability').toList() : preferenceFields;
  List<RequirementField> get _generalSchema => [
    ..._infoSchema, ..._siteSchema, ..._ruleSchema, ..._operationalSchema,
    ...technicalFields, ..._designSchema, ...deliveryFields,
  ];
  ProjectScenario? get _currentScenario => scenarioFor(_category?.id, _group?.id, _type?.id, _configurationId);
  ProjectScenarioVariant? get _currentVariant {
    final scenario = _currentScenario;
    if (scenario == null) return null;
    return scenarioVariantFor(scenario, int.tryParse(_floors.text.trim()), _parking?.name);
  }
  bool get _canAutoPlan => _currentScenario?.generator != null;
  bool get _needsScenarioInputs => int.tryParse(_floors.text.trim()) == null || _parking == null;
  bool get _isReview => _step == _steps.length - 1;
  bool get _showsContinue => _step >= 3;
  String get _selectionPath => [
        if (_step > 0) _category!.label,
        if (_step > 1) _group!.label,
        if (_step > 2) _type!.label,
      ].join(' › ');

  @override
  void initState() {
    super.initState();
    final project = widget.existingProject;
    if (project == null) {
      final variant = widget.variant;
      final preset = variant?.scenario ?? widget.scenario;
      if (preset != null) {
        _category = preset.category;
        _group = preset.group;
        _type = preset.type;
        _configurationId = preset.configuration?.id;
        if (variant != null) {
          _floors.text = '${variant.floors}';
          _parking = ProjectParking.values.byName(variant.parkingId);
        }
        _step = 3;
      }
      return;
    }
    final brief = project.brief;
    final saved = brief?.taxonomy;
    _name.text = project.name;
    _width.text = project.width > 0 ? project.width.toString() : '';
    _depth.text = project.length > 0 ? project.length.toString() : '';
    _floors.text = brief?.floorCount?.toString() ?? '';
    _facing = _directions.contains(project.facing) ? project.facing : null;
    _parking = brief?.parking;
    if (saved != null) {
      _category = taxonomyCategory(saved.categoryId);
      _group = taxonomyGroup(_category, saved.subcategoryId);
      _type = taxonomyChoice(_group?.types ?? const [], saved.typeId);
      _unsupportedBrief = saved.version != projectTaxonomyVersion || _type == null;
      _configurationId = saved.configurationId;
      _actionId = saved.actionId;
      _stageId = saved.stageId;
      _shapeId = saved.plotShapeId;
      _spaces.addAll(saved.spaceQuantities.map((key, value) => MapEntry(key, '$value')));
      final requirements = brief?.requirements;
      if (requirements != null) {
        _unsupportedBrief = _unsupportedBrief || requirements.version != requirementsSchemaVersion;
        _answers.addAll(requirements.answers);
        _customSpaces.addAll(requirements.customSpaces);
        _spaceDetails.addAll(requirements.spaceDetails);
        for (final entry in _spaceDetails.entries) {
          if (isExcludedSpace(entry.value)) _spaces.putIfAbsent(entry.key, () => '1');
        }
        if (_type != null) {
          for (final field in _facilitySchema) {
            final value = _answers.remove(field.id);
            if (value != null) _facilityAnswers[field.id] = value;
          }
        }
      }
    } else if (brief != null && brief.type != null) {
      final path = switch (brief.type!) {
        ProjectType.singleRoom => ('residential', 'houses', 'single_room'),
        ProjectType.house => ('residential', 'houses', 'independent_house'),
        ProjectType.villa => ('residential', 'houses', 'villa'),
        ProjectType.farmhouse => ('residential', 'houses', 'farmhouse'),
        ProjectType.bungalow => ('residential', 'houses', 'bungalow'),
        ProjectType.apartments => ('residential', 'apartments', switch (project.bhk) {
          '1 BHK' => '1_bhk', '2 BHK' => '2_bhk', '3 BHK' => '3_bhk',
          '4 BHK' => '4_bhk', '5+ BHK' => '5_plus_bhk', _ => 'apartment_building',
        }),
        ProjectType.shop => ('commercial', 'retail', 'shop'),
        ProjectType.office => ('commercial', 'office', 'small_office'),
        ProjectType.warehouse => ('industrial', 'logistics', 'general_warehouse'),
        ProjectType.mixedUse => ('mixed_use', 'mixed_development', switch (project.bhk) {
          'Shops + homes' => 'residential_plus_retail',
          'Offices + homes' => 'residential_plus_office',
          'Shops + offices' => 'office_plus_retail', _ => 'mixed_use_development',
        }),
      };
      _category = taxonomyCategory(path.$1);
      _group = taxonomyGroup(_category, path.$2);
      _type = taxonomyChoice(_group?.types ?? const [], path.$3);
      // The previous wizard explicitly collected rectangular plot dimensions.
      _shapeId = 'rectangular';
      if (_type != null) {
        for (final choice in _program.configurations) {
          if (choice.label.toLowerCase() == project.bhk.toLowerCase()) {
            _configurationId = choice.id;
          }
        }
        for (final choice in _program.spaces) {
          if (brief.features.any((label) => label.toLowerCase() == choice.label.toLowerCase())) {
            _spaces[choice.id] = '1';
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _depth.dispose();
    _floors.dispose();
    super.dispose();
  }

  void _categorySelected(TaxonomyCategory category) {
    setState(() {
      if (_category?.id != category.id) {
        _category = category;
        _group = null;
        _type = null;
        _clearProgram();
      }
      _step = 1;
    });
  }

  void _groupSelected(TaxonomyGroup group) {
    setState(() {
      if (_group?.id != group.id) {
        _group = group;
        _type = null;
        _clearProgram();
      }
      _typeQuery = '';
      _step = 2;
    });
  }

  void _typeSelected(TaxonomyChoice type) {
    setState(() {
      if (_type?.id != type.id) {
        _type = type;
        _clearProgram();
      }
      _step = 3;
    });
  }

  void _clearProgram() {
    _configurationId = null;
    _spaces.clear();
    _customSpaces.clear();
    _spaceDetails.clear();
    _facilityAnswers.clear();
    _answers.remove(customTypeField.id);
    _answers.remove(customSiteKindField.id);
    _answers.remove(customConfigurationField.id);
    _sectionError = null;
  }

  void _back() {
    if (_saving) return;
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      FocusScope.of(context).unfocus();
      setState(() { _step--; _sectionError = null; });
    }
  }

  void _next() {
    final form = _step == 4 ? _spaceForm : _sectionForms[_step];
    if (form.currentState?.validate() == false) {
      setState(() => _sectionError = 'Correct the highlighted fields before continuing.');
      return;
    }
    final issue = switch (_step) {
      4 => _spaceProgramIssue(),
      6 => !_linearSite && _answers['survey_boundary']?.toString().trim().isNotEmpty == true && _answers['coordinate_unit'] == null
          ? 'Select the survey coordinate unit when entering a boundary.' : null,
      8 => _facilityIssue(),
      11 => _answers['budget']?.toString().trim().isNotEmpty == true && _answers['currency']?.toString().trim().isNotEmpty != true
          ? 'Enter the currency for the budget amount.' : null,
      _ => null,
    };
    if (issue != null) {
      setState(() => _sectionError = issue);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _step++; _sectionError = null; });
  }

  String? _spaceProgramIssue() => validateSpaceProgram({
    for (final space in _allSpaces)
      if (_spaces.containsKey(space.id)) space.id: space.label,
  }, _spaceDetails);

  String? _facilityIssue() {
    final floors = int.tryParse(_floors.text);
    final typical = int.tryParse('${_answers['typical_floors'] ?? ''}');
    if (!_linearSite && floors != null && typical != null && typical > floors) {
      return 'Typical floors cannot exceed total floors above grade.';
    }
    if (!_linearSite && floors != null && _facilityAnswers['house_form'] == 'single_floor' && floors != 1) {
      return 'Single-floor house and the total floor count do not match.';
    }
    final bedrooms = int.tryParse('${_facilityAnswers['bedrooms'] ?? ''}');
    if (bedrooms != null && _facilitySchema.any((f) => f.id == 'bedrooms')) {
      final exactBhk = RegExp(r'^([1-5])_bhk$').firstMatch(_configurationId ?? '');
      if (exactBhk != null && bedrooms != int.parse(exactBhk.group(1)!)) {
        return 'Bedroom count must match the selected BHK. Go back to change the configuration if needed.';
      }
      if (_configurationId == '6_plus_bhk' && bedrooms < 6) return '6+ BHK requires at least six bedrooms.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProjectProvider>();
    final notifications = context.read<NotificationProvider>();
    final project = widget.existingProject;
    final name = _name.text.trim();
    final width = _isRectangular ? double.tryParse(_width.text.trim()) : null;
    final length = _shapeId == 'square' ? width : (_isRectangular ? double.tryParse(_depth.text.trim()) : null);
    final facing = _linearSite ? 'Not decided' : _facing ?? 'Not decided';
    final layout = taxonomyChoice(_program.configurations, _configurationId)?.label ?? '';
    final previous = project?.brief;
    final brief = ProjectBrief(
      type: previous?.type,
      legacyLayout: previous?.legacyLayout ??
          (previous?.type != null && previous?.taxonomy == null ? project?.bhk : null),
      taxonomy: TaxonomySelection(
        version: projectTaxonomyVersion,
        categoryId: _category!.id,
        subcategoryId: _group!.id,
        typeId: _type!.id,
        configurationId: _configurationId,
        actionId: _actionId,
        stageId: _stageId,
        plotShapeId: _linearSite ? null : _shapeId,
        scenarioId: _currentVariant?.id ?? _currentScenario?.id,
        spaceQuantities: activeSpaceQuantities(_spaces, _spaceDetails),
      ),
      requirements: ProjectRequirementsSnapshot(
        version: requirementsSchemaVersion,
        answers: {
          ...requirementAnswers(_generalSchema, _answers),
          ...requirementAnswers(_facilitySchema, _facilityAnswers),
        },
        customSpaces: _customSpaces,
        spaceDetails: {
          for (final item in _spaceDetails.entries)
            if (_spaces.containsKey(item.key)) item.key: {
              for (final detail in item.value.entries)
                if (!isExcludedSpace(item.value) || !spaceAdjacencyKeys.contains(detail.key))
                  detail.key: detail.value,
            },
        },
      ),
      floorCount: _linearSite ? null : int.tryParse(_floors.text.trim()),
      parking: _linearSite ? null : _parking,
      features: previous?.features ?? const [],
    );
    setState(() => _saving = true);
    try {
      if (project == null) {
        await provider.addProject(
          name: name, length: length ?? 0, width: width ?? 0, bhk: layout,
          floors: brief.floorLabel, facing: facing, brief: brief,
        );
      } else {
        await provider.updateProject(
          id: project.id, name: name, length: length ?? 0, width: width ?? 0,
          bhk: layout, floors: brief.floorLabel, facing: facing, brief: brief,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('Could not save the project. Please try again.')));
      return;
    }
    if (!mounted) return;
    final title = project == null ? 'New Project Created' : 'Project Updated';
    unawaited(notifications.addNotification('success', title, '$name • ${_type!.label}').catchError(
      (Object error, StackTrace stack) => debugPrint('Unable to save project notification: $error'),
    ));
    if (AutomaticFloorPlanGenerator.supportsBrief(brief)) {
      Navigator.of(context).pushReplacement<void, void>(MaterialPageRoute(
        builder: (_) => AutomaticFloorPlanScreen(projectName: name, brief: brief,
          frontageFt: width ?? 0, depthFt: length ?? 0, facing: facing),
      ));
    } else {
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Project brief saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = _unsupportedBrief
        ? const Text('This brief uses an unavailable taxonomy version or type. Its saved data has not been changed.')
        : switch (_step) {
            0 => _selectionList(
                'Choose a category (required).',
                projectTaxonomy.map((c) => _selectionTile(c.label, c.id == _category?.id, () => _categorySelected(c))),
              ),
            1 => _selectionList(
                'Choose a subcategory (required).',
                _category!.groups.map((g) => _selectionTile(g.label, g.id == _group?.id, () => _groupSelected(g))),
              ),
            2 => _buildTypes(),
            3 => _buildConfiguration(),
            4 => _buildSpaces(),
            5 => _buildProjectInfo(),
            6 => _buildSite(),
            7 => _section('Authority data is recorded as provided. This app has not verified it.', _ruleSchema),
            8 => _buildFacility(),
            9 => _section('Record technical requirements for coordination and specialist review.', technicalFields),
            10 => _section('These are preferences, not verified design constraints. Vastu never overrides safety or local rules.', _designSchema),
            11 => _section('Capture budget, schedule and desired outputs. This does not enable generation or export.', deliveryFields),
            _ => _buildReview(),
          };
    return PopScope<void>(
      canPop: _step == 0 && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existingProject == null ? 'New Project' : 'Edit Project'),
          leading: BackButton(onPressed: _saving ? () {} : _back),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text('STEP ${_step + 1} OF ${_steps.length}', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: (_step + 1) / _steps.length),
                    const SizedBox(height: 12),
                    Text(_steps[_step], style: theme.textTheme.headlineSmall),
                    if (_step > 0)
                      Text(_selectionPath, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Expanded(
                      child: SingleChildScrollView(
                        key: ValueKey(_step),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: body,
                      ),
                    ),
                    if (_sectionError != null)
                      Text(_sectionError!, style: TextStyle(color: theme.colorScheme.error)),
                    if (_showsContinue)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: FilledButton(
                          onPressed: _saving ? null : (_isReview ? _save : _next),
                          child: Text(_saving ? 'Saving…' : (_isReview ? 'Save project brief' : 'Continue')),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionList(String prompt, Iterable<Widget> tiles) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text(prompt), const SizedBox(height: 8), ...tiles],
      );

  Widget _selectionTile(String label, bool selected, VoidCallback onTap) => Card(
        child: ListTile(
          title: Text(label),
          trailing: Icon(selected ? Icons.check : Icons.chevron_right),
          selected: selected,
          onTap: onTap,
        ),
      );

  Widget _buildTypes() {
    final query = _typeQuery.trim().toLowerCase();
    final matches = _group!.types.where((type) => type.label.toLowerCase().contains(query));
    return _selectionList('Choose a project type (required).', [
      TextFormField(
        initialValue: _typeQuery,
        decoration: const InputDecoration(labelText: 'Search project types', prefixIcon: Icon(Icons.search)),
        onChanged: (value) => setState(() => _typeQuery = value),
      ),
      const SizedBox(height: 8),
      if (matches.isEmpty) const Text('No matching project types.'),
      for (final type in matches)
        _selectionTile(type.label, type.id == _type?.id, () => _typeSelected(type)),
    ]);
  }

  Widget _buildConfiguration() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown('${_program.configurationLabel} (optional)',
            _configurationId, _program.configurations,
            (value) => setState(() {
              if (_configurationId != value) _answers.remove(customConfigurationField.id);
              _configurationId = value;
            }),
          ),
          const SizedBox(height: 12),
          if (_canAutoPlan)
            const Text('Automatic CAD for the ground-floor, no-parking variant. Requires a rectangular or square plot and a cardinal frontage.')
          else
            const Text('Brief only for this selection. Automatic CAD plans: ${AutomaticFloorPlanGenerator.availability}'),
        ],
      );

  Widget _buildSpaces() => Form(
        key: _spaceForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select spaces or components, then configure each one. This is not a code-required room schedule.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _addCustomSpace, icon: const Icon(Icons.add), label: const Text('Add an unlisted space')),
            for (final space in _allSpaces)
              Column(
                key: ValueKey(space.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(space.label),
                    value: _spaces.containsKey(space.id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _spaces[space.id] = '1';
                      } else {
                        _removeSpace(space.id);
                      }
                    }),
                  ),
                  if (_spaces.containsKey(space.id)) ...[
                    if (!isExcludedSpace(_spaceDetails[space.id])) TextFormField(
                      initialValue: _spaces[space.id],
                      decoration: InputDecoration(labelText: '${space.label} quantity (required)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => _spaces[space.id] = value,
                      validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0 ? null : 'Enter a positive quantity.',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: () => _editSpace(space),
                        child: Text(_spaceDetails[space.id]?.isNotEmpty == true ? 'Edit ${space.label} details' : 'Add ${space.label} details')),
                    ),
                  ],
                ],
              ),
          ],
        ),
      );

  void _removeSpace(String id) {
    _spaces.remove(id);
    _customSpaces.remove(id);
    _spaceDetails.remove(id);
    for (final entry in _spaceDetails.entries.toList()) {
      final updated = Map<String, Object>.of(entry.value);
      for (final key in spaceAdjacencyKeys) {
        final current = updated[key];
        if (current is Iterable) {
          final remaining = current.whereType<String>().where((value) => value != id).toList();
          if (remaining.isEmpty) { updated.remove(key); } else { updated[key] = remaining; }
        }
      }
      _spaceDetails[entry.key] = updated;
    }
  }

  Future<void> _addCustomSpace() async {
    final names = _allSpaces.map((space) => space.label.toLowerCase()).toSet();
    final form = GlobalKey<FormState>();
    var draft = '';
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Add an unlisted space'),
      content: Form(key: form, child: TextFormField(
        decoration: const InputDecoration(labelText: 'Space name (required)'),
        maxLength: 80,
        onChanged: (value) => draft = value.trim(),
        validator: (_) => draft.isEmpty ? 'Enter a name.' : names.contains(draft.toLowerCase()) ? 'That space is already listed.' : null,
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (form.currentState!.validate()) Navigator.pop(context, draft);
        }, child: const Text('Add space')),
      ],
    ));
    if (!mounted || name == null) return;
    setState(() {
      var index = 1;
      while (_customSpaces.containsKey('custom_space_$index')) { index++; }
      final id = 'custom_space_$index';
      _customSpaces[id] = name;
      _spaces[id] = '1';
    });
  }

  List<RequirementField> _spaceSchema(String id) {
    final prior = _spaceDetails[id];
    final referenced = {
      for (final key in spaceAdjacencyKeys)
        if (prior?[key] is Iterable) ...(prior![key] as Iterable).whereType<String>(),
    };
    return spaceDetailFields([
      for (final space in _allSpaces)
        if (space.id != id && _spaces.containsKey(space.id))
          if (!isExcludedSpace(_spaceDetails[space.id])) space
          else if (referenced.contains(space.id))
            TaxonomyChoice(space.id, '${space.label} (excluded)'),
    ]);
  }

  Future<void> _editSpace(TaxonomyChoice space) async {
    final details = await showDialog<Map<String, Object>>(context: context,
      builder: (_) => SpaceRequirementsDialog(title: space.label,
        fields: _spaceSchema(space.id), values: _spaceDetails[space.id] ?? const {}),
    );
    if (details != null && mounted) setState(() {
      _spaceDetails[space.id] = details;
      _sectionError = null;
    });
  }

  Widget _fieldPanel(List<RequirementField> fields, {bool facility = false}) {
    final values = facility ? _facilityAnswers : _answers;
    return RequirementFields(fields: fields, values: values,
      onChanged: (id, value) {
        if (value == null) { values.remove(id); } else { values[id] = value; }
        if (_sectionError != null) setState(() => _sectionError = null);
      },
      onChoiceChanged: () => setState(() {}),
    );
  }

  Widget _section(String introduction, List<RequirementField> fields) => Form(
    key: _sectionForms[_step],
    child: _selectionList(introduction, [_fieldPanel(fields)]),
  );

  Widget _buildProjectInfo() => Form(
    key: _sectionForms[_step],
    child: _selectionList('Identify the project and its scope. Leave unknown information blank.', [
      TextFormField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'Project name (required)'),
        validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a project name.' : null,
      ),
      const SizedBox(height: 12),
      _dropdown('Project action (optional)', _actionId, projectActions, (value) => setState(() => _actionId = value)),
      const SizedBox(height: 12),
      _dropdown('Project stage (optional)', _stageId, projectStages, (value) => setState(() => _stageId = value)),
      const SizedBox(height: 12),
      _fieldPanel(_infoSchema),
    ]),
  );

  Widget _buildSite() => Form(
    key: _sectionForms[_step],
    child: _selectionList(_linearSite ? 'Record alignment and corridor data from your survey.' : 'Record measured plot data and site conditions.', [
      if (!_linearSite) ...[
        _dropdown('Plot geometry (optional)', _shapeId, plotShapes, (value) => setState(() {
          if (_shapeId != value) { _width.clear(); _depth.clear(); _shapeId = value; }
        })),
        const SizedBox(height: 12),
        if (_isRectangular) ...[
          _dimension(_width, _shapeId == 'square' ? 'Plot side (ft)' : 'Plot width / frontage (ft)'),
          if (_shapeId == 'rectangular') ...[
            const SizedBox(height: 12),
            _dimension(_depth, 'Plot depth (ft)'),
          ],
          const SizedBox(height: 12),
        ] else if (_shapeId != null) ...[
          const Text('Record survey dimensions below. Boundary notes are not converted to plan geometry yet.'),
          const SizedBox(height: 12),
        ],
        _dropdown('Front-facing side (optional)', _facing, [
          for (final direction in _directions)
            TaxonomyChoice(direction, direction == 'Not decided' ? 'Unknown / survey required' : direction),
        ], (value) => setState(() => _facing = value)),
        const SizedBox(height: 12),
      ],
      _fieldPanel(_siteSchema),
    ]),
  );

  Widget _buildFacility() => Form(
    key: _sectionForms[_step],
    child: _selectionList('Provide capacities and requirements for ${_type!.label}. Do not enter estimated constraints as verified data.', [
      if (!_linearSite) ...[
        TextFormField(
          controller: _floors,
          decoration: const InputDecoration(labelText: 'Floors above grade (optional)', helperText: 'Include the ground floor. Leave blank if unknown or not applicable.'),
          keyboardType: TextInputType.number,
          validator: (value) => (value ?? '').trim().isEmpty || (int.tryParse(value!.trim()) ?? -1) >= 0 ? null : 'Enter a non-negative whole number.',
        ),
        const SizedBox(height: 12),
        _dropdown('Parking (optional)', _parking?.name, [
          for (final parking in ProjectParking.values) TaxonomyChoice(parking.name, parking.label),
        ], (value) => setState(() => _parking = value == null ? null : ProjectParking.values.byName(value))),
        const SizedBox(height: 12),
      ],
      _fieldPanel(_facilitySchema, facility: true),
      const Divider(),
      _fieldPanel(_operationalSchema),
    ]),
  );

  Widget _dimension(TextEditingController controller, String label) => TextFormField(
        key: ValueKey(label),
        controller: controller,
        decoration: InputDecoration(labelText: label, helperText: 'Optional; enter measured dimensions only.'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (input) {
          if ((input ?? '').trim().isEmpty) {
            if (_shapeId == 'rectangular' && (_width.text.trim().isNotEmpty || _depth.text.trim().isNotEmpty)) {
              return 'Enter both dimensions or leave both blank.';
            }
            return null;
          }
          final number = double.tryParse(input!.trim());
          final width = double.tryParse(_width.text.trim());
          final depth = _shapeId == 'square' ? width : double.tryParse(_depth.text.trim());
          if (width != null && depth != null && !(width * depth).isFinite) {
            return 'Enter dimensions with a valid plot area.';
          }
          return number != null && number.isFinite && number > 0 && (number * 304.8).isFinite
              ? null : 'Enter a positive dimension in feet.';
        },
      );

  // Use a distinct sentinel to let a user clear an optional field.
  Widget _dropdown(String label, String? selected, List<TaxonomyChoice> options,
      ValueChanged<String?> onChanged) {
    final current = taxonomyChoice(options, selected)?.id ?? '';
    return DropdownButtonFormField<String>(
      key: ValueKey(label),
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Not specified')),
        for (final option in options)
          DropdownMenuItem(value: option.id, child: Text(option.label, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (value) => onChanged(value == '' ? null : value),
    );
  }

  Widget _buildReview() {
    final width = _isRectangular ? _width.text.trim() : '';
    final depth = _isRectangular ? _depth.text.trim() : '';
    final pending = [
      if (['city', 'address'].every((key) => _answers[key]?.toString().trim().isNotEmpty != true)) 'location',
      if (_linearSite ? alignmentFields.every((f) => f.normalized(_answers[f.id]) == null) : width.isEmpty && _answers['survey_boundary']?.toString().trim().isNotEmpty != true) 'measured site data',
      if (!_linearSite && (_facing == null || _facing == 'Not decided')) 'orientation',
      if (_answers['rule_status'] != 'reference_provided') 'local rule reference',
      if (_answers['jurisdiction']?.toString().trim().isNotEmpty != true) 'jurisdiction',
      if (activeSpaceQuantities(_spaces, _spaceDetails).isEmpty) 'space program',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_name.text.trim(), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('User-provided brief • Not verified'),
        _reviewRow('Project action', taxonomyChoice(projectActions, _actionId)?.label),
        _reviewRow('Project stage', taxonomyChoice(projectStages, _stageId)?.label),
        _reviewRow(_program.configurationLabel, taxonomyChoice(_program.configurations, _configurationId)?.label),
        if (_currentVariant != null) _reviewRow('Scenario variant', _currentVariant!.label),
        if (!_linearSite) _reviewRow('Plot geometry', taxonomyChoice(plotShapes, _shapeId)?.label),
        if (!_linearSite && _shapeId == 'square') ...[
          _reviewRow('Measured plot side', width.isEmpty ? null : '$width ft'),
          if (width.isNotEmpty) _reviewRow('Plot footprint (derived from square)', '$width × $width ft'),
        ] else if (!_linearSite)
          _reviewRow('Plot dimensions', width.isEmpty || depth.isEmpty ? null : '$width × $depth ft'),
        if (!_linearSite) _reviewRow('Site orientation', _facing == 'Not decided' ? 'Unknown / survey required' : _facing),
        if (!_linearSite) _reviewRow('Floors above grade', _floors.text.trim()),
        if (!_linearSite) _reviewRow('Parking', _parking?.label),
        const Divider(),
        if (_spaces.isEmpty) _reviewRow('Space / room program', 'No spaces selected'),
        for (final space in _allSpaces)
          if (_spaces.containsKey(space.id)) ...[
            _reviewRow(space.label, isExcludedSpace(_spaceDetails[space.id]) ? 'Excluded from layout' : 'Quantity: ${_spaces[space.id]}'),
            ..._reviewAnswers(_spaceSchema(space.id), _spaceDetails[space.id] ?? const {}),
          ],
        const Divider(),
        ..._reviewAnswers(_generalSchema, _answers),
        ..._reviewAnswers(_facilitySchema, _facilityAnswers),
        if (pending.isNotEmpty) _reviewRow('Still needed before planning', pending.join(', ')),
        const SizedBox(height: 12),
        const Text('Survey and local rules have not been verified. Specialist review may be required.'),
        const SizedBox(height: 8),
        if (_canAutoPlan && _needsScenarioInputs)
          const Text('Input needed for CAD: confirm the floor count and parking on the facility page.')
        else if (_canAutoPlan && _currentVariant?.generator == null)
          const Text('Brief only for this floor and parking variant. Saving will explain why a drawing could not be generated.')
        else if (_canAutoPlan)
          const Text('Saving automatically opens the CAD concept preview or explains why this brief cannot be generated. Select one floor, No parking, measured plot sides and a cardinal frontage.')
        else
          const Text('This brief is saved without a drawing. Automatic CAD plans: ${AutomaticFloorPlanGenerator.availability}'),
        if (_canAutoPlan) const Text('A generated drawing can be saved as DXF. PDF is not available yet.'),
      ],
    );
  }

  Iterable<Widget> _reviewAnswers(List<RequirementField> fields, Map<String, Object> answers) sync* {
    for (final field in fields) {
      if (!field.applies(answers)) continue;
      final value = field.display(answers[field.id]);
      if (value != null) yield _reviewRow(field.label, value);
    }
  }

  Widget _reviewRow(String label, String? value) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(value == null || value.isEmpty ? 'Not provided' : value),
        dense: true,
      );
}
