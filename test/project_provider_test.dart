import 'dart:convert';

import 'package:architect_engine/providers/project_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> add(ProjectProvider provider, String name) => provider.addProject(
    name: name, length: 30, width: 20, bhk: '1 BHK',
    floors: 'Ground floor', facing: 'North',
  );

  test('failed writes do not appear in projects or create a duplicate on retry', () async {
    var accept = false;
    final provider = ProjectProvider(writeProjects: (_) async => accept);
    addTearDown(provider.dispose);
    await expectLater(add(provider, 'House'), throwsStateError);
    expect(provider.projects, isEmpty);
    accept = true;
    await add(provider, 'House');
    expect(provider.projects.map((project) => project.name), ['House']);
  });

  test('concurrent operations persist a complete snapshot with unique IDs', () async {
    var saved = <String>[];
    final provider = ProjectProvider(writeProjects: (data) async {
      saved = data;
      return true;
    });
    addTearDown(provider.dispose);
    await Future.wait([add(provider, 'A'), add(provider, 'B')]);
    expect(saved.map((entry) => jsonDecode(entry)['name']), ['B', 'A']);
    expect(provider.projects.map((project) => project.id).toSet(), hasLength(2));
  });

  test('failed edits leave the previously saved project intact', () async {
    var accept = true;
    final provider = ProjectProvider(writeProjects: (_) async => accept);
    addTearDown(provider.dispose);
    await add(provider, 'Original');
    accept = false;
    await expectLater(provider.updateProject(id: provider.projects.single.id,
      name: 'Changed', length: 40, width: 20, bhk: '2 BHK',
      floors: 'Ground floor', facing: 'North'), throwsStateError);
    expect(provider.projects.single.name, 'Original');
    expect(provider.projects.single.length, 30);
  });
}
