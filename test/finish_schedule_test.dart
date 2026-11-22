import 'package:architect_engine/models/finish_measurement.dart';
import 'package:architect_engine/models/project_model.dart';
import 'package:architect_engine/providers/project_provider.dart';
import 'package:architect_engine/screens/finish_schedule_screen.dart';
import 'package:architect_engine/services/finish_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const wall = FinishMeasurement(location: 'Level 1 / North wall', kind: 'wall', material: 'T-01',
  length: 4, width: 3, deduction: 2, count: 2, waste: 10);
const floor = FinishMeasurement(location: 'Level 1 / Lobby', kind: 'floor', material: ' t-01 ', length: 2, width: 2);
const trim = FinishMeasurement(location: 'Yard edge', kind: 'trim', material: 'T-01', length: 5, deduction: .5, count: 2);

ProjectModel project() => ProjectModel(id: 'p1', name: 'Finish test', length: 20, width: 40, bhk: '', floors: '',
  facing: 'Not decided', createdAt: DateTime(2026), updatedAt: DateTime(2026));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('net and waste are measured per repeat, totals never mix linear and surface units', () {
    final result = FinishSchedule([wall, floor, trim]);
    expect(result.issue, isNull);
    expect(wall.gross, 24);
    expect(wall.net, 20);
    expect(result.totals.map((t) => (t.material, t.unit, t.net, t.allowance)),
      [('T-01', 'm²', 24, 26), ('T-01', 'm', 9, 9)]);
    final csv = result.toCsv()!;
    expect(csv, contains('"Level 1 / North wall","Wall face","T-01","m²",4.000000,3.000000,2.000000,2,24.000000,20.000000,10.000000,22.000000'));
    expect(csv, contains('total,,,"T-01","m²",,,,,,24.000000,,26.000000'));
  });

  test('invalid rows suppress export and text cells cannot be interpreted as formulas', () {
    expect(FinishSchedule([]).toCsv(), isNull);
    const invalid = FinishMeasurement(location: 'Wall', kind: 'wall', material: 'P', length: 2, width: 3, deduction: 6);
    expect(FinishSchedule([wall, invalid]).issue, contains('Row 2'));
    expect(FinishSchedule([wall, invalid]).toCsv(), isNull);
    expect(FinishMeasurement.fromMap(invalid.toMap()), isNull);
    const formula = FinishMeasurement(location: '  =2+2', kind: 'trim', material: 'a,"b"', length: 1);
    expect(FinishSchedule([formula]).toCsv(), contains('"\'  =2+2","Trim / edge","a,""b"""'));
  });

  test('project edit, duplication and reload preserve measured rows independently of the CAD brief', () async {
    SharedPreferences.setMockInitialValues({'ae_projects_v1': [project().toJson()]});
    final provider = ProjectProvider();
    addTearDown(provider.dispose);
    await provider.saveFinishMeasurements('p1', [wall, trim]);
    await provider.updateProject(id: 'p1', name: 'Updated', width: 10, length: 50, floors: '', bhk: '', facing: 'East');
    await provider.duplicateProject('p1');
    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getStringList('ae_projects_v1')!.map(ProjectModel.fromJson).toList();
    expect(persisted.map((p) => p.name), ['Updated (Copy)', 'Updated']);
    for (final copy in persisted) {
      expect(copy.finishMeasurements.map((row) => row.net), [20, 9]);
    }
    await provider.saveFinishMeasurements('p1', []);
    expect(provider.projects.first.finishMeasurements.length, 2);
    expect(provider.projects.last.finishMeasurements, isEmpty);
  });

  testWidgets('add and persist a measured floor row from an existing project', (tester) async {
    final p = project();
    SharedPreferences.setMockInitialValues({'ae_projects_v1': [p.toJson()]});
    await tester.binding.setSurfaceSize(const Size(850, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => ProjectProvider(),
      child: MaterialApp(home: FinishScheduleScreen(project: p))));
    expect(find.text('Share finish CSV'), findsNothing);
    await tester.tap(find.text('Add measurement'));
    await tester.pumpAndSettle();
    for (final (label, value) in [('Location / reference', 'Lobby'), ('Material code / specification', 'T-01'),
      ('Measured length (m)', '4'), ('Measured width or height (m)', '3')]) {
      await tester.enterText(find.widgetWithText(TextField, label), value);
    }
    await tester.tap(find.text('Save measurement'));
    await tester.pumpAndSettle();
    expect(find.text('Lobby'), findsOneWidget);
    expect(find.textContaining('Net 12 m²'), findsWidgets);
    expect(find.text('Share finish CSV'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(ProjectModel.fromJson(prefs.getStringList('ae_projects_v1')!.single).finishMeasurements.single.net, 12);
  });
}
