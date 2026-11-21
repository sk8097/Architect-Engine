import '../data/healthcare_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;
import 'enclosed_cad_generator.dart';

class ClinicCadResult {
  const ClinicCadResult(this.plan, this.issue);
  final AutomaticFloorPlan? plan;
  final String? issue;
}

/// Outpatient concept with two entirely disconnected indoor circulation graphs.
/// No clinical, fire, accessibility or infection-control claim is inferred.
class HealthcareCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'clinic_separated';

  ClinicCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    ClinicCadResult stop(String issue) => ClinicCadResult(null, issue);
    final sel = brief.taxonomy, source = brief.requirements;
    if (sel == null || source == null || sel.version != projectTaxonomyVersion || source.version != requirementsSchemaVersion) {
      return stop('Save a clinic brief with the current measured requirements.');
    }
    if (sel.categoryId != 'institutional' || sel.subcategoryId != 'healthcare' || !separatedClinicTypes.contains(sel.typeId)) {
      return stop('This separate-route template is for listed outpatient clinics, not hospital, inpatient or specialist-department design.');
    }
    final values = source.answers;
    if (sel.configurationId != null && sel.configurationId != 'outpatient') return stop('This template only supports outpatient care.');
    if ((values['beds'] as num? ?? 0) > 0 || (values['procedure_rooms'] as num? ?? 0) > 0) return stop('Bed and procedure-room planning is not supported by this outpatient template.');
    final departments = values['clinical_departments'];
    if (departments is Iterable && departments.any((id) => !const {'opd','pharmacy'}.contains(id))) {
      return stop('Only outpatient and pharmacy departments are supported in this route template. Specialist departments need a separate circulation design.');
    }
    if (values['hc_transfer'] != 'not_required') return stop('Confirm that independent external access is sufficient. This template cannot provide an internal transfer between the wings.');
    final serviceEntry = values['hc_service_entry'];
    if (serviceEntry != 'same' && serviceEntry != 'opposite') return stop('Choose same-frontage or opposite-side service entrance.');
    const opposite = {'North':'South','South':'North','East':'West','West':'East'};
    if (!opposite.containsKey(facing)) return stop('Choose a measured cardinal patient entrance side.');
    int? mm(Object? value, {bool zero = false}) {
      if (value is! num || !value.isFinite || value < 0 || value > 300) return null;
      final result = (value * 1000).round();
      return result > 0 || zero ? result : null;
    }
    double m(int value) => value / 1000;
    final plotW = mm(widthFt * .3048), plotD = mm(depthFt * .3048);
    final width = mm(values['cad_plate_width']), depth = mm(values['cad_plate_depth']);
    final left = mm(values['cad_offset_left'], zero: true), front = mm(values['cad_offset_front'], zero: true);
    final patientW = mm(values['hc_patient_width']), serviceCorridor = mm(values['hc_service_corridor']);
    if (plotW == null || plotD == null || width == null || depth == null || left == null || front == null || patientW == null || serviceCorridor == null) {
      return stop('Enter measured site, whole clinic envelope, offsets, patient wing width and service passage width.');
    }
    if (patientW >= width) return stop('Patient wing width must be less than the whole clinic width so the service wing has room.');
    final right = plotW - left - width, rear = plotD - front - depth;
    if (right < 0 || rear < 0) return stop('The two-wing shell extends beyond the plot.');
    final setbacks = <String,int>{};
    for (final side in ['left','right','front','rear']) {
      final v = values['${side}_setback'];
      final inset = v == null ? 0 : mm(v, zero: true);
      if (inset == null) return stop('Invalid $side setback.');
      setbacks[side] = inset;
    }
    if (left < setbacks['left']! || right < setbacks['right']! || front < setbacks['front']! || rear < setbacks['rear']!) {
      return stop('The two-wing clinic exceeds the supplied setbacks.');
    }
    final coverage = values['coverage_limit'], fsi = values['fsi_limit'];
    if (coverage is num && width * depth > plotW * plotD * coverage / 100) return stop('Combined clinic footprint exceeds supplied site coverage.');
    if (fsi is num && width * depth > plotW * plotD * fsi) return stop('Combined clinic area exceeds supplied FAR/FSI.');
    final counts = sel.spaceQuantities;
    final group = taxonomyGroup(taxonomyCategory(sel.categoryId), sel.subcategoryId)!;
    final type = taxonomyChoice(group.types, sel.typeId)!;
    final labels = {for (final option in taxonomyProgram(group,type).spaces) option.id: option.label, ...source.customSpaces};
    final route = <String, String>{};
    var consultRooms = 0;
    for (final entry in counts.entries) {
      final id = entry.key, name = labels[entry.key] ?? entry.key;
      final detail = source.spaceDetails[id] ?? const <String,Object>{};
      final wing = detail['hc_route'];
      if (unsupportedClinicRoomIds.contains(id)) return stop('$name requires a specialist clinical layout that this template does not model.');
      if (wing != 'patient' && wing != 'service') return stop('$name: assign a patient or staff/service route in Space details.');
      if ((patientRoomIds.contains(id) && wing != 'patient') || (serviceRoomIds.contains(id) && wing != 'service')) {
        return stop('$name: the assigned route conflicts with the room’s role in this template.');
      }
      route[id] = wing as String;
      if (id == 'consultation') consultRooms += entry.value;
    }
    if (route['waiting'] != 'patient' || (route['consultation'] != 'patient' && route['examination'] != 'patient')) {
      return stop('Add measured waiting and consultation or examination rooms to the patient route.');
    }
    if (route['staff_facilities'] != 'service' && route['staff_change'] != 'service' && route['clinical_store'] != 'service') {
      return stop('Add measured staff facilities, staff changing or a clinical store to the service route.');
    }
    if (values['consult_rooms'] is num && values['consult_rooms'] != consultRooms) return stop('The consultation room quantity must match the saved consultation count.');
    if (departments is Iterable && departments.contains('pharmacy') && !route.containsKey('pharmacy')) return stop('Include a measured pharmacy room for the requested department.');
    for (final id in route.keys) {
      final required = source.spaceDetails[id]?['adjacent_required'];
      if (required is Iterable && required.any((other) => route[other] != null && route[other] != route[id])) {
        return stop('${labels[id]} requires adjacency across the patient/service divider. Move the requirement to one route or use a design with internal transfer.');
      }
    }
    TowerInputs wingInput(String name, {required bool service}) {
      final reversed = service && serviceEntry == 'opposite';
      final selected = counts.keys.where((id) => route[id] == name).toSet();
      final briefForWing = ProjectBrief(floorCount: brief.floorCount, parking: brief.parking, features: brief.features,
        taxonomy: TaxonomySelection(version: sel.version, categoryId: sel.categoryId, subcategoryId: sel.subcategoryId,
          typeId: sel.typeId, configurationId: sel.configurationId, actionId: sel.actionId,
          plotShapeId: sel.plotShapeId, spaceQuantities: {for (final id in selected) id: counts[id]!}),
        requirements: ProjectRequirementsSnapshot(version: source.version, customSpaces: source.customSpaces,
          answers: {...values,
            'cad_output': 'building',
            'cad_plate_width': m(service ? width - patientW : patientW),
            'cad_offset_left': m(reversed ? right : (service ? left + patientW : left)),
            'cad_offset_front': m(reversed ? rear : front),
            if (service) 'cad_corridor': m(serviceCorridor),
            if (reversed) ...{'left_setback': m(setbacks['right']!), 'right_setback': m(setbacks['left']!),
              'front_setback': m(setbacks['rear']!), 'rear_setback': m(setbacks['front']!)},
          },
          spaceDetails: {
            for (final id in selected) id: {
              ...?source.spaceDetails[id],
              if (source.spaceDetails[id]?['separate_from'] case final Iterable list)
                'separate_from': list.whereType<String>().where(selected.contains).toList(),
            },
          },
        ));
      return (brief: briefForWing, facing: reversed ? opposite[facing]! : facing);
    }
    final wholeLocal = PlanRect(left, front, left + width, front + depth);
    final whole = switch (facing) {
      'North' => PlanRect(right, rear, right + width, rear + depth),
      'East' => PlanRect(rear, left, rear + depth, left + width),
      'West' => PlanRect(front, right, front + depth, right + width),
      _ => wholeLocal,
    };
    bool exteriorWindow(PlanOpening opening) {
      final b = opening.bounds;
      return opening.kind != PlanOpeningKind.window || b.left == whole.left || b.right == whole.right ||
        b.bottom == whole.bottom || b.top == whole.top;
    }
    final plans = <AutomaticFloorPlan>[];
    for (final name in ['patient', 'service']) {
      final input = wingInput(name, service: name == 'service');
      final result = EnclosedCadGenerator().generate(input.brief, widthFt: widthFt, depthFt: depthFt, facing: input.facing,
        extraAcceptance: (candidate) => candidate.openings.every(exteriorWindow));
      if (result.sheets.isEmpty) return stop('${name == 'patient' ? 'Patient' : 'Staff/service'} wing: ${result.issues.join(' ')} '
        'Requested windows must reach the outer shell, not the centre divider.');
      plans.add(result.sheets.single.plan);
    }
    final (p, s) = (plans[0], plans[1]);
    final a = p.footprint, b = s.footprint;
    if (a.overlaps(b)) return stop('Patient and service wings overlap.');
    final combined = PlanRect(a.left < b.left ? a.left : b.left, a.bottom < b.bottom ? a.bottom : b.bottom,
      a.right > b.right ? a.right : b.right, a.top > b.top ? a.top : b.top);
    if (combined.area != a.area + b.area || !whole.contains(combined) || !combined.contains(whole)) return stop('The two wings do not form a complete rectangular envelope.');
    final rooms = <PlanRoom>[];
    final openings = <PlanOpening>[];
    for (var i = 0; i < plans.length; i++) {
      final prefix = i == 0 ? 'patient' : 'service';
      final plan = plans[i];
      for (final room in plan.rooms) {
        rooms.add(PlanRoom('${prefix}_${room.id}', room.id == 'internal_passage'
          ? (i == 0 ? 'Patient passage' : 'Staff / service passage') : room.label, room.bounds));
      }
      for (final opening in plan.openings) {
        if (!exteriorWindow(opening)) return stop('A window falls on the shared divider.');
        openings.add(PlanOpening(opening.kind, opening.bounds,
          opening.from == AutomaticFloorPlan.entry ? opening.from : '${prefix}_${opening.from}', '${prefix}_${opening.to}'));
      }
    }
    final plan = AutomaticFloorPlan(plot: p.plot, footprint: combined, facing: facing,
      sheetTitle: '${type.label} / SEPARATE CLINIC ROUTES', rooms: rooms,
      walls: [...p.walls, ...s.walls], openings: openings);
    final partition = validatePlanPartition(plan);
    return partition == null ? ClinicCadResult(plan, null) : stop('Combined drawing did not pass geometry validation: $partition');
  }
}

typedef TowerInputs = ({ProjectBrief brief, String facing});
