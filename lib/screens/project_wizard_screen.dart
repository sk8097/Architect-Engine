import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/project_taxonomy.dart';
import '../data/project_requirements.dart';
import '../data/project_scenarios.dart';
import '../data/space_planning.dart';
import '../models/project_brief.dart';
import '../models/project_model.dart';
import '../models/project_requirements_snapshot.dart';
import '../providers/notification_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/requirement_fields.dart';
import '../services/automatic_floor_plan_generator.dart';
import 'automatic_floor_plan_screen.dart';
import 'tower_planner_screen.dart';

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
  String get _programId => _type?.programId ?? _group?.programId ?? '';
  bool get _home => _programId == 'home';
  int get _floorCount => int.tryParse(_floors.text.trim()) ?? 0;
  bool get _terrace => _answers['terrace_needed'] == 'yes';
  bool get _vastu => const {'review', 'user'}.contains(_answers['vastu']);
  Iterable<int> get _levels => Iterable<int>.generate(_floorCount.clamp(0, 100).toInt());
  int get _bedrooms => int.tryParse('${_facilityAnswers['bedrooms'] ?? ''}') ??
    int.tryParse(RegExp(r'^([1-5])_(?:bhk|bedroom)$').firstMatch(_configurationId ?? '')?.group(1) ?? '') ??
    (const {'1_rk', 'studio'}.contains(_configurationId) ? 0 : -1);
  int get _baths => (int.tryParse('${_facilityAnswers['common_toilets'] ?? ''}') ?? 1) +
    (int.tryParse('${_facilityAnswers['attached_toilets'] ?? ''}') ?? 0);
  String _levelName(int n) => n == 0 ? 'Ground floor' : 'Floor $n';
  List<RequirementField> get _essential => [
    for (final field in _facilitySchema)
      if ((planningEssentialIds[_programId] ?? const <String>{}).contains(field.id)) asRequired(field),
    if (_home) ...[
      for (final field in _facilitySchema)
        if (const {'bedrooms', 'common_toilets', 'attached_toilets', 'kitchen_type'}.contains(field.id)) field,
    ],
  ];
  String get _plotUnit => _answers['plot_unit'] == 'm' ? 'm' : 'ft';
  double? _measuredFeet(TextEditingController controller) {
    final n = positiveNumber(controller.text);
    if (n == null) return null;
    final feet = _plotUnit == 'm' ? n / .3048 : n;
    return feet.isFinite ? feet : null;
  }
  void _changePlotUnit(String? choice) {
    final next = choice ?? 'ft';
    if (next == _plotUnit) return;
    final width = _measuredFeet(_width), depth = _measuredFeet(_depth);
    setState(() {
      _answers['plot_unit'] = next;
      if (width != null) _width.text = _dimensionInSelectedUnit(width);
      if (depth != null) _depth.text = _dimensionInSelectedUnit(depth);
      _sectionError = null;
    });
  }
  String _dimensionInSelectedUnit(double feet) => _plotUnit == 'm'
      ? (feet * .3048).toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '') : feet.toString();
  List<RequirementField> get _frontPlanning => [
    if (_isRectangular) planningChoice('plot_unit', 'Plot measurement unit', {'ft': 'Feet', 'm': 'Metres'}, required: false),
    if (_customInfrastructure) customSiteKindField,
    if (_type?.id == 'custom') customTypeField,
    if (_configurationId == 'custom') customConfigurationField,
    if (_linearSite)
      ...alignmentFields.take(3).map((field) => field.id == 'alignment_reference' ? field : asRequired(field))
    else if (_shapeId != null && !_isRectangular)
      asRequired(surveyedPlotFields.first),
    if (!_linearSite) planningChoice('vastu', 'Vastu preference', {
      'none': 'No Vastu preference', 'review': 'Consider Vastu', 'user': 'Use my Vastu preferences', 'undecided': 'Not decided',
    }, required: false),
    if (!_linearSite) planningChoice('terrace_needed', 'Accessible terrace?', {'yes': 'Yes', 'no': 'No'}, required: false),
    if (_home) ...residentialPlanningFields(_vastu),
    if (!_linearSite) ...accessPlanningFields(_floorCount, _terrace, _wantsParking),
    if (_terrace && _answers['terrace_use'] is Iterable)
      for (final zone in (_answers['terrace_use'] as Iterable).whereType<String>())
        if (const {'open', 'covered', 'enclosed', 'garden'}.contains(zone))
          planningArea('terrace_area_$zone', 'Area for $zone terrace zone'),
  ];
  List<RequirementField> _levelFields(int level) => [
    if (level > 0) planningArea('level_area_$level', 'Available floor area'),
    if (_floorCount > 1) planningArea('level_access_$level', 'Stair, landing and lift allowance'),
    if (_home && _floorCount > 1) ...[
      RequirementField('level_bedrooms_$level', 'Bedrooms on this floor', kind: RequirementKind.integer, min: 0, required: true),
      RequirementField('level_baths_$level', 'Bathrooms on this floor', kind: RequirementKind.integer, min: 0, required: true),
    ],
  ];
  List<RequirementField> get _floorPlanning => _linearSite ? [] : [
    if (_home && _floorCount > 1)
      planningChoice('main_kitchen_floor', 'Main kitchen and living-room floor', {
        for (final n in _levels) '$n': _levelName(n),
      }),
    for (final n in _levels) ..._levelFields(n),
  ];
  Set<String> get _earlyIds => {..._frontPlanning.map((f) => f.id), 'surveyed_plot_area', 'route_length', 'right_of_way', 'alignment_reference', 'vastu', 'vastu_notes'};
  bool _earlyOptionalSize(String id) => _home && const {
    'master_bedroom','secondary_bedroom','childrens_bedroom','guest_bedroom','elderly_accessible_bedroom',
    'family_living_room','open_kitchen','closed_kitchen','shared_bathroom','attached_bathroom',
    'staircase','lift','terrace','prayer_puja_room',
  }.contains(id);
  bool _coveredByCore(String id) => _earlyOptionalSize(id) ||
      const {'staircase','lift','terrace'}.contains(id) && (_floorCount > 1 || _terrace);
  int? _spaceLevel(Map<String, Object> data) {
    final level = '${data['floor_level'] ?? ''}'.trim().toLowerCase();
    if (const {'', 'ground', 'ground floor', 'g'}.contains(level)) return 0;
    return int.tryParse(level.replaceFirst(RegExp(r'^floor\s+'), ''));
  }
  PlanningSize? _sizeFor(String id) => _home ? homeRoomSizes[id] : null;
  ({double? minimum, double? typical, double? width, double? depth}) _roomAllocation(String id) {
    final room = _spaceDetails[id] ?? const <String, Object>{};
    final fallback = _sizeFor(id);
    final width = positiveNumber(room['width']);
    final length = positiveNumber(room['length']);
    final unit = room['area_unit'];
    final conversion = unit == 'sqm' ? sqftPerSqm : 1.0;
    final min = unit == null ? null : positiveNumber(room['area_min']);
    final target = unit == null ? null : positiveNumber(room['area_target']);
    final fromSides = width == null || length == null ? null : width * length * sqftPerSqm;
    final supplied = [if (min != null) min * conversion, if (fromSides != null) fromSides];
    final least = supplied.isNotEmpty ? supplied.reduce((a,b) => a > b ? a : b) :
      (target == null ? fallback?.minimum : target * conversion);
    return (minimum: least, typical: target == null ? (fallback?.typical ?? least) : target * conversion,
      width: width == null ? fallback?.width : width / .3048,
      depth: length == null ? fallback?.depth : length / .3048);
  }
  AreaBudget _budget(int level) {
    final width = _isRectangular ? _measuredFeet(_width) : null;
    final depth = _shapeId == 'square' ? width : (_isRectangular ? _measuredFeet(_depth) : null);
    final area = positiveNumber(_answers['surveyed_plot_area']);
    final intNumber = (String key) => int.tryParse('${_answers[key] ?? ''}') ?? 0;
    final home = !_home ? (minimum: 0.0, typical: 0.0) : _floorCount > 1
      ? homeLevelAllowance(intNumber('level_bedrooms_$level'), intNumber('level_baths_$level'), _answers['main_kitchen_floor'] == '$level')
      : dwellingAllowance(_bedrooms < 0 ? 0 : _bedrooms, _baths);
    final allowance = (_floorCount > 1 ? positiveNumber(_answers['level_access_$level']) ?? 0.0 : 0.0) + (level == 0 ?
      ((_terrace && _floorCount == 1 ? positiveNumber(_answers['ground_access_area']) ?? 0.0 : 0) +
       (_wantsParking ? positiveNumber(_answers['parking_sqft']) ?? 0.0 : 0)) : 0);
    final puja = _home && level == 0 && _answers['puja_needed'] == 'yes' ? pujaSizes[_answers['puja_form']] : null;
    var minimum = home.minimum + allowance + (puja?.minimum ?? 0.0);
    var typical = home.typical + allowance + (puja?.typical ?? 0.0);
    var unknown = false;
    for (final entry in activeSpaceQuantities(_spaces, _spaceDetails).entries) {
      if (_coveredByCore(entry.key) || _spaceLevel(_spaceDetails[entry.key] ?? const {}) != level) continue;
      final allocation = _roomAllocation(entry.key);
      if (allocation.minimum == null) { unknown = true; continue; }
      minimum += allocation.minimum! * entry.value;
      final guess = allocation.typical ?? allocation.minimum!;
      typical += (guess < allocation.minimum! ? allocation.minimum! : guess) * entry.value;
    }
    return estimatePlanningArea(width: level == 0 ? width : null, depth: level == 0 ? depth : null,
      surveyedSqft: level > 0 ? positiveNumber(_answers['level_area_$level']) :
        (_isRectangular || area == null ? null : area * sqftPerSqm),
      rules: _answers, minimum: minimum, typical: typical, unknown: unknown);
  }
  AreaBudget get _roofBudget {
    final zones = _answers['terrace_use'];
    final used = zones is Iterable ? zones.whereType<String>().fold<double>(0,
      (sum, zone) => sum + (positiveNumber(_answers['terrace_area_$zone']) ?? 0)) : 0.0;
    return estimatePlanningArea(surveyedSqft: positiveNumber(_answers['terrace_sqft']), minimum: used, typical: used);
  }
  List<RequirementField> get _infoSchema => [
    ...projectInformationFields,
    if (_actionId != null && !const {'new_design', 'feasibility', 'concept_design', 'master_planning'}.contains(_actionId)) previousDesignField,
  ];
  List<RequirementField> get _siteSchema => [
    ...siteCommonFields,
    for (final field in (_linearSite ? alignmentFields : surveyedPlotFields))
      if (!_earlyIds.contains(field.id)) field,
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
      ? preferenceFields.where((f) => f.id == 'sustainability').toList()
      : preferenceFields.where((f) => !_earlyIds.contains(f.id)).toList();
  List<RequirementField> get _generalSchema => [
    ..._frontPlanning, ..._floorPlanning, ..._infoSchema, ..._siteSchema, ..._ruleSchema, ..._operationalSchema,
    ...technicalFields, ..._designSchema, ...deliveryFields,
  ];
  ProjectScenario? get _currentScenario => scenarioForRequirements(
    _category?.id, _group?.id, _type?.id, _configurationId,
    _facilitySchema.any((field) => field.id == 'bedrooms')
        ? int.tryParse('${_facilityAnswers['bedrooms'] ?? ''}') : null,
  );
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
        if (_plotUnit == 'm') {
          if (project.width > 0) _width.text = _dimensionInSelectedUnit(project.width);
          if (project.length > 0) _depth.text = _dimensionInSelectedUnit(project.length);
        }
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
    if (widget.existingProject == null && _category?.id == 'special' && _group?.id == 'complex' &&
        type.id == 'high_rise_supertall_building') {
      Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const TowerPlannerScreen()));
      return;
    }
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
      3 => _planningIssue(),
      4 => _spaceProgramIssue() ?? _planningIssue(checkRooms: true),
      7 => _planningIssue(checkRooms: true),
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

  String? _planningIssue({bool checkRooms = false}) {
    if (_linearSite) {
      if (positiveNumber(_answers['route_length']) == null || positiveNumber(_answers['right_of_way']) == null) {
        return 'Enter the measured route length and available right-of-way.';
      }
      return null;
    }
    if (_shapeId == null) return 'Select the geometry of your site.';
    if (_budget(0).total <= 0) return 'Enter the measured site size before continuing.';
    if (_vastu && (_facing == null || _facing == 'Not decided')) return 'Enter the measured frontage direction for Vastu suggestions.';
    if (_home && (_floorCount < 1 || _floorCount > 100)) return 'Enter the total floor count, including the ground floor.';
    if (_home && _facing == null) return 'Select the frontage direction or mark it unknown.';
    if (_home && _bedrooms < 0) return 'Enter the bedroom count or choose a configuration with a known count.';
    if (_home && _parking == null) return 'Choose whether you need parking.';
    if (_home && _baths < 1) return 'A dwelling needs at least one bathroom in this brief.';
    final facility = _facilityIssue();
    if (facility != null) return facility;
    if (_floorCount > 1 && _home) {
      int sum(String name) => _levels.fold(0, (total, n) => total + (int.tryParse('${_answers['level_${name}_$n'] ?? ''}') ?? 0));
      if (sum('bedrooms') != _bedrooms || sum('baths') != _baths) {
        return 'The bedroom and bathroom counts on individual floors must add up to your total requirements.';
      }
    }
    if (_terrace && _roofBudget.remaining < -0.001) return 'The requested terrace zones exceed the available terrace area.';
    for (final level in {0, ..._levels}) {
      final area = _budget(level);
      if (area.remaining < -0.001) return '${_levelName(level)} needs more area than you have entered. Review the budget and your selections.';
      if (_home && area.width != null && area.depth != null &&
          (_floorCount <= 1 || _answers['main_kitchen_floor'] == '$level') &&
          !homeRoomSizes['family_living_room']!.fits(area.width!, area.depth!)) {
        return 'The measured width and depth cannot fit the concept living-room allowance.';
      }
    }
    if (checkRooms) {
      for (final entry in activeSpaceQuantities(_spaces, _spaceDetails).entries) {
        final label = _customSpaces[entry.key] ?? taxonomyChoice(_program.spaces, entry.key)?.label ?? entry.key;
        final detail = _spaceDetails[entry.key] ?? const <String, Object>{};
        final level = _spaceLevel(detail);
        if (level == null || level < 0 || (level > 0 && level >= _floorCount)) return '$label: choose an existing floor by level number (0 for ground).';
        if (_coveredByCore(entry.key)) continue;
        final allocation = _roomAllocation(entry.key);
        if (allocation.minimum == null) return '$label: enter an area with units or both clear dimensions in its details.';
        final area = _budget(level);
        if (area.width != null && area.depth != null && allocation.width != null && allocation.depth != null &&
            !PlanningSize(allocation.width!, allocation.depth!, allocation.minimum!).fits(area.width!, area.depth!)) {
          return '$label does not fit the available width and depth.';
        }
      }
    }
    return null;
  }

  Widget _areaSummary() {
    final ground = _budget(0);
    String number(double n) => n.toStringAsFixed(0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text('Plot: ${number(ground.total)} sqft  •  Usable estimate: ${number(ground.available)} sqft',
        style: Theme.of(context).textTheme.labelMedium),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (final n in {0, ..._levels})
          Padding(padding: const EdgeInsets.only(right: 12), child: Text(
            '${_levelName(n)}: ${number(_budget(n).minimum)} planned / ${number(_budget(n).remaining)} left',
            style: Theme.of(context).textTheme.labelSmall)),
        if (_terrace) Text('Terrace: ${number(_roofBudget.minimum)} planned / ${number(_roofBudget.remaining)} left',
          style: Theme.of(context).textTheme.labelSmall),
      ])),
      if ({0, ..._levels}.any((n) => _budget(n).unknown)) const Text('Not counted: spaces without size inputs.'),
      if (_step == 3 || _step == 4)
        Text('Ground floor typical: ${number(ground.typical)} sqft • Concept estimates only',
          style: Theme.of(context).textTheme.labelSmall),
    ]);
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
    final issue = _planningIssue(checkRooms: true);
    if (issue != null) { setState(() => _sectionError = issue); return; }
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProjectProvider>();
    final notifications = context.read<NotificationProvider>();
    final project = widget.existingProject;
    final name = _name.text.trim();
    final width = _isRectangular ? _measuredFeet(_width) : null;
    final length = _shapeId == 'square' ? width : (_isRectangular ? _measuredFeet(_depth) : null);
    final facing = _linearSite ? 'Not decided' : _facing ?? 'Not decided';
    final layout = _currentScenario?.configuration?.label ?? '';
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
                    if (!_unsupportedBrief && _step >= 3 && !_linearSite && _budget(0).total > 0)
                      _areaSummary(),
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

  Widget _buildConfiguration() => Form(
    key: _sectionForms[_step],
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_customInfrastructure) _fieldPanel([customSiteKindField]),
      if (!_linearSite) ...[
        _dropdown('Plot geometry (required)', _shapeId, plotShapes, (value) => setState(() => _shapeId = value), required: true),
        const SizedBox(height: 12),
        if (_isRectangular) ...[
          _dropdown('Plot units', _plotUnit, const [TaxonomyChoice('ft', 'Feet'), TaxonomyChoice('m', 'Metres')], _changePlotUnit),
          const SizedBox(height: 12),
          _dimension(_width, _shapeId == 'square' ? 'Plot side ($_plotUnit)' : 'Plot width / frontage ($_plotUnit)'),
          if (_shapeId == 'rectangular') ...[
            const SizedBox(height: 12),
            _dimension(_depth, 'Plot depth ($_plotUnit)'),
          ],
          const SizedBox(height: 12),
        ],
      ],
      _fieldPanel(_frontPlanning.where((f) =>
        const {'surveyed_plot_area', 'route_length','right_of_way','alignment_reference','vastu'}.contains(f.id)).toList()),
      if ((_home || _vastu) && !_linearSite) ...[
        _facingPicker(required: true),
        if (_vastu && _facing != null && _facing != 'Not decided')
          const Text('Vastu review: consider northeast for puja, southeast for kitchen and southwest for the main bedroom when feasible. These are preferences, not layout or approval checks.'),
      ],
      if (_linearSite ? positiveNumber(_answers['route_length']) != null && positiveNumber(_answers['right_of_way']) != null : _budget(0).total > 0) ...[
      const SizedBox(height: 12),
      if (!_linearSite) ...[
        TextFormField(
          key: const ValueKey('floor_count'),
          controller: _floors,
          decoration: InputDecoration(labelText: _home ? 'Floors above grade (required)' : 'Floors above grade (optional)',
            helperText: 'Include the ground floor. Up to 100 levels in this brief.'),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _sectionError = null),
          validator: (value) {
            if (!_home && (value ?? '').trim().isEmpty) return null;
            final n = int.tryParse((value ?? '').trim());
            return n != null && n >= (_home ? 1 : 0) && n <= 100 ? null : 'Enter a valid floor count (up to 100).';
          },
        ),
        const SizedBox(height: 12),
      ],
      _dropdown('${_program.configurationLabel} (optional)', _configurationId, _program.configurations,
        (value) => setState(() {
          if (_configurationId != value) { _answers.remove(customConfigurationField.id); _sectionError = null; }
          _configurationId = value;
        }), available: (option) {
          if (!_home || _floorCount > 1) return true;
          final area = _budget(0);
          final bedrooms = int.tryParse(RegExp(r'^([1-5])_(?:bhk|bedroom)$').firstMatch(option.id)?.group(1) ?? '');
          return bedrooms == null || area.total <= 0 || dwellingAllowance(bedrooms, _baths).minimum <= area.available;
        }),
      const SizedBox(height: 12),
      if (_home) const Text('Kitchen and at least one bathroom are included. Enter a bedroom count if you skip the configuration label.'),
      _fieldPanel(_essential, facility: true),
      if (!_linearSite) ...[
        _dropdown(_home ? 'Parking (required)' : 'Parking (optional)', _parking?.name, [
          for (final parking in ProjectParking.values) TaxonomyChoice(parking.name, parking.label),
        ], (value) => setState(() => _parking = value == null ? null : ProjectParking.values.byName(value)), required: _home),
        const SizedBox(height: 12),
      ],
      if (_isRectangular) ExpansionTile(
        title: const Text('Known setbacks (optional)'),
        maintainState: true,
        children: [_fieldPanel(jurisdictionFields.where((f) => f.id.endsWith('_setback')).toList())],
      ),
      _fieldPanel(_frontPlanning.where((f) =>
        !const {'plot_unit','custom_site_kind','surveyed_plot_area','route_length','right_of_way','alignment_reference','vastu'}.contains(f.id)).toList()),
      if (_floorCount > 1 && !_linearSite) ...[
        _fieldPanel(_floorPlanning.where((f) => f.id == 'main_kitchen_floor').toList()),
        for (final level in _levels) ...[
          const Divider(),
          Text(_levelName(level), style: Theme.of(context).textTheme.titleSmall),
          _fieldPanel(_levelFields(level)),
        ],
      ],
      ],
    ]),
  );

  Widget _facingPicker({bool required = false}) => _dropdown(
    required ? 'Front-facing side (required)' : 'Front-facing side (optional)', _facing, [
    for (final direction in _directions)
      TaxonomyChoice(direction, direction == 'Not decided' ? 'Unknown / survey required' : direction),
  ], (value) => setState(() => _facing = value), required: required);

  bool _canAddSpace(String id) {
    final size = _sizeFor(id);
    if (_linearSite || size == null || _coveredByCore(id)) return true;
    return {0, ..._levels}.any((n) => _budget(n).fits(size));
  }

  Widget? _spaceHint(String id) {
    if (_linearSite) return null;
    if (_coveredByCore(id)) return const Text('Already allowed for in the main requirements; optional room details.');
    final size = _sizeFor(id);
    if (size == null) return const Text('Enter your size in Details if selected.');
    if (!_spaces.containsKey(id) && !_canAddSpace(id)) return const Text('Not enough space in the entered floor budgets.');
    return Text('Concept minimum ${size.minimum.toStringAsFixed(0)} sqft • Typical ${size.typical.toStringAsFixed(0)} sqft');
  }

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
                    subtitle: _spaceHint(space.id),
                    value: _spaces.containsKey(space.id),
                    onChanged: !_spaces.containsKey(space.id) && !_canAddSpace(space.id) ? null : (checked) => setState(() {
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
                      onChanged: (value) => setState(() => _spaces[space.id] = value),
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
        setState(() => _sectionError = null);
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
      if (!_linearSite && !_vastu && !_home) _facingPicker(),
      _fieldPanel(_siteSchema),
    ]),
  );

  Widget _buildFacility() => Form(
    key: _sectionForms[_step],
    child: _selectionList('Provide capacities and requirements for ${_type!.label}. Do not enter estimated constraints as verified data.', [
      _fieldPanel(_facilitySchema.where((field) => !_essential.any((early) => early.id == field.id)).toList(), facility: true),
      const Divider(),
      _fieldPanel(_operationalSchema),
    ]),
  );

  Widget _dimension(TextEditingController controller, String label) => TextFormField(
        key: ValueKey(label),
        controller: controller,
        decoration: InputDecoration(labelText: '$label (required)'),
        onChanged: (_) => setState(() => _sectionError = null),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (input) {
          if ((input ?? '').trim().isEmpty) return 'Enter the measured dimension.';
          final number = double.tryParse(input!.trim());
          final width = _measuredFeet(_width);
          final depth = _shapeId == 'square' ? width : _measuredFeet(_depth);
          if (width != null && depth != null && !(width * depth).isFinite) {
            return 'Enter dimensions with a valid plot area.';
          }
          return number != null && number.isFinite && number > 0 && (number * 304.8).isFinite
              ? null : 'Enter a positive dimension in $_plotUnit.';
        },
      );

  // Use a distinct sentinel to let a user clear an optional field.
  Widget _dropdown(String label, String? selected, List<TaxonomyChoice> options,
      ValueChanged<String?> onChanged, {bool required = false, bool Function(TaxonomyChoice)? available}) {
    final current = taxonomyChoice(options, selected)?.id ?? '';
    return DropdownButtonFormField<String>(
      key: ValueKey(label),
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Not specified')),
        for (final option in options)
          DropdownMenuItem(value: option.id, enabled: available?.call(option) ?? true,
            child: Text(available?.call(option) == false ? '${option.label} — not enough area' : option.label, overflow: TextOverflow.ellipsis)),
      ],
      validator: required ? (value) => value == null || value.isEmpty ? 'Select an option.' : null : null,
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
        if (_configurationId == null && _currentScenario?.configuration != null)
          _reviewRow('Layout label (derived from bedroom count)', _currentScenario!.configuration!.label),
        if (!_linearSite) _reviewRow('Plot geometry', taxonomyChoice(plotShapes, _shapeId)?.label),
        if (!_linearSite && _shapeId == 'square') ...[
          _reviewRow('Measured plot side', width.isEmpty ? null : '$width $_plotUnit'),
          if (width.isNotEmpty) _reviewRow('Plot footprint (derived from square)', '$width × $width $_plotUnit'),
        ] else if (!_linearSite)
          _reviewRow('Plot dimensions', width.isEmpty || depth.isEmpty ? null : '$width × $depth $_plotUnit'),
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
          const Text('Saving checks your requirements and automatically opens the CAD concept if they fit. If they do not, your brief is kept as entered and the app explains why no drawing was created.')
        else
          const Text('Your requirements will be saved as entered. No automatic drawing is available for this selection yet.'),
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
