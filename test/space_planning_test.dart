import 'package:architect_engine/data/project_requirements.dart';
import 'package:architect_engine/data/project_taxonomy.dart';
import 'package:architect_engine/data/space_planning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plot sqft and user setbacks reduce space before options are counted', () {
    final budget = estimatePlanningArea(width: 100, depth: 200,
      rules: {'left_setback': 3.048, 'rear_setback': 3.048}, minimum: 500, typical: 650);
    expect(budget.total, 20000);
    expect(budget.available, closeTo(17100, .01));
    expect(budget.remaining, closeTo(16600, .01));
    expect(estimatePlanningArea(width: 4, depth: 400).fits(homeRoomSizes['study']!), isFalse);
    expect(estimatePlanningArea(width: 20, depth: 20, minimum: 375).fits(homeRoomSizes['study']!), isFalse);
    expect(estimatePlanningArea(width: 20, depth: 20, minimum: 350).fits(homeRoomSizes['study']!), isTrue);
  });

  test('dwelling minimum and typical reserve one bath and a kitchen', () {
    final basic = dwellingAllowance(1, 0);
    expect(basic, dwellingAllowance(1, 1));
    expect(basic.minimum, lessThan(basic.typical));
    expect(dwellingAllowance(2, 1).minimum, greaterThan(basic.minimum));
    expect(homeLevelAllowance(0, 0, false).minimum, 0);
    expect(homeLevelAllowance(0, 1, false).minimum, greaterThan(0));
  });

  test('each non-house program has its own required brief inputs', () {
    for (final category in projectTaxonomy) {
      for (final group in category.groups) {
        for (final type in group.types) {
          final program = type.programId ?? group.programId;
          if (program == 'home') continue;
          final ids = planningEssentialIds[program];
          expect(ids, isNotNull, reason: program);
          final fields = facilityFields(group, type);
          for (final id in ids!) {
            final requiredField = asRequired(fields.firstWhere((field) => field.id == id));
            expect(requiredField.validate(null), isNotNull);
          }
        }
      }
    }
  });

  test('vertical access and terrace inputs are conditional and required once enabled', () {
    expect(accessPlanningFields(1, false, false), isEmpty);
    expect(accessPlanningFields(2, false, false).map((f) => f.id), contains('stair_form'));
    final roof = accessPlanningFields(1, true, false);
    expect(roof.map((f) => f.id), containsAll(['terrace_use', 'terrace_sqft', 'ground_access_area']));
    expect(roof.every((f) => f.validate(null) != null), isTrue);
  });
}
