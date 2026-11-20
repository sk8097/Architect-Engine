import 'dart:convert';

import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/models/project_requirements_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each selectable type has a nonempty facility schema with unique field IDs', () {
    for (final category in projectTaxonomy) {
      for (final group in category.groups) {
        expect(group.types.where((t) => t.id == 'custom'), hasLength(1));
        for (final type in group.types) {
          final ids = facilityFields(group, type).map((field) => field.id).toList();
          expect(ids, isNotEmpty, reason: '${group.id}/${type.id}');
          expect(ids.toSet(), hasLength(ids.length), reason: '${group.id}/${type.id}');
        }
      }
    }
  });

  test('an authority source is required only when claimed and otherwise not saved', () {
    final field = jurisdictionFields.singleWhere((f) => f.id == 'rule_reference');
    expect(field.applies({'rule_status': 'unavailable'}), isFalse);
    expect(field.applies({'rule_status': 'reference_provided'}), isTrue);
    expect(field.validate(' '), isNotNull);
    expect(requirementAnswers(jurisdictionFields, {'rule_status': 'unavailable', 'rule_reference': 'Old reference'}),
      {'rule_status': 'unavailable'});
  });

  test('numbers retain their type and invalid counts / non-finite dimensions are rejected', () {
    final route = alignmentFields.singleWhere((f) => f.id == 'route_length');
    final floors = buildingProgramFields.singleWhere((f) => f.id == 'typical_floors');
    expect(route.normalized('152.4'), 152.4);
    expect(route.validate('Infinity'), isNotNull);
    expect(floors.validate('3.5'), isNotNull);
  });

  test('room dimensions and adjacency have cross-field validation', () {
    expect(validateSpaceDetails({'area_target': 20}), isNotNull);
    expect(validateSpaceDetails({'area_unit': 'sqm', 'area_min': 15, 'area_target': 10}), isNotNull);
    expect(validateSpaceDetails({'area_unit': 'sqm', 'area_min': 10, 'area_target': 15, 'area_max': 20}), isNull);
    expect(validateSpaceDetails({'adjacent_required': ['kitchen'], 'separate_from': ['kitchen']}), isNotNull);
  });

  test('adjacency cannot contradict separation entered from another space', () {
    final issue = validateSpaceProgram(
      {'kitchen': 'Kitchen', 'dining': 'Dining'},
      {
        'kitchen': {'adjacent_required': ['dining']},
        'dining': {'separate_from': ['kitchen']},
      },
    );
    expect(issue, contains('Kitchen'));
    expect(issue, contains('Dining'));
  });

  test('excluded rooms do not have a demand and cannot be adjacency targets', () {
    final details = <String, Map<String, Object>>{
      'garden': {'priority': 'excluded'},
      'dining': {'adjacent_preferred': ['garden']},
    };
    expect(activeSpaceQuantities({'garden': '1', 'dining': '2'}, details), {'dining': 2});
    expect(validateSpaceProgram({'garden': 'Garden', 'dining': 'Dining'}, details), contains('excluded'));
  });

  test('requirement schema version and structured answers round trip without dropping types', () {
    final original = ProjectRequirementsSnapshot(version: requirementsSchemaVersion,
      answers: {'jurisdiction': 'Local authority', 'alternatives': 2, 'ev_bays': 0, 'export_interest': ['dxf', 'pdf']},
      customSpaces: {'custom_space_1': 'Music booth'},
      spaceDetails: {'custom_space_1': {'area_unit': 'sqm', 'area_target': 12.5}});
    final decoded = ProjectRequirementsSnapshot.fromMap(jsonDecode(jsonEncode(original.toMap())))!;
    expect(decoded.toMap(), original.toMap());
    expect(() => (decoded.answers['export_interest'] as List<String>).add('ifc'), throwsUnsupportedError);
  });
}
