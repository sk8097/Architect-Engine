import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_brief.dart';
import '../models/project_model.dart';

class ProjectProvider extends ChangeNotifier {
  static const _storageKey = 'ae_projects_v1';
  final Future<bool> Function(List<String>) _writeProjects;
  List<ProjectModel> _projects = [];
  late Future<void> _pending;
  bool _disposed = false;

  List<ProjectModel> get projects => List.unmodifiable(_projects);
  bool get hasProjects => _projects.isNotEmpty;

  ProjectProvider({Future<bool> Function(List<String>)? writeProjects})
      : _writeProjects = writeProjects ?? _writePreferences {
    _pending = Future.value();
    _loaded = _loadProjects();
    // The mutation that awaits _loaded still reports the failure to its caller.
    // Attach a listener now so a failed startup read cannot become unhandled.
    _loaded.then<void>((_) {}, onError: (Object error, StackTrace stack) {
      debugPrint('Unable to read saved projects: $error');
    });
  }

  late final Future<void> _loaded;

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    _projects = jsonList.map(ProjectModel.fromJson).toList();
    if (!_disposed) notifyListeners();
  }

  static Future<bool> _writePreferences(List<String> projects) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_storageKey, projects);
  }

  // Build a candidate snapshot and publish it only after a successful write.
  // Serialize mutations so the next snapshot always starts from saved state.
  Future<void> _mutate(List<ProjectModel> Function() candidate) {
    final result = _pending.then<void>((_) async {
      await _loaded;
      final next = candidate();
      final saved = await _writeProjects(next.map((project) => project.toJson()).toList());
      if (!saved) throw StateError('Project storage did not accept the change.');
      _projects = next;
      if (!_disposed) notifyListeners();
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  String _newId(DateTime time) {
    final base = 'p_${time.microsecondsSinceEpoch}';
    var id = base;
    var suffix = 0;
    while (_projects.any((project) => project.id == id)) {
      id = '${base}_${++suffix}';
    }
    return id;
  }

  Future<void> addProject({
    required String name,
    required double length,
    required double width,
    required String bhk,
    required String floors,
    required String facing,
    ProjectBrief? brief,
  }) => _mutate(() {
    final now = DateTime.now();
    return [
      ProjectModel(id: _newId(now), name: name, length: length, width: width,
        bhk: bhk, floors: floors, facing: facing, brief: brief,
        createdAt: now, updatedAt: now),
      ..._projects,
    ];
  });

  Future<void> updateProject({
    required String id,
    required String name,
    required double length,
    required double width,
    required String bhk,
    required String floors,
    required String facing,
    ProjectBrief? brief,
  }) => _mutate(() {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index == -1) throw StateError('The project no longer exists.');
    final original = _projects[index];
    return [..._projects]..[index] = ProjectModel(
      id: id, name: name, length: length, width: width, bhk: bhk,
      floors: floors, facing: facing, brief: brief ?? original.brief,
      createdAt: original.createdAt, updatedAt: DateTime.now(),
    );
  });

  Future<void> duplicateProject(String id) => _mutate(() {
    final original = _projects.firstWhere((project) => project.id == id);
    final now = DateTime.now();
    return [
      ProjectModel(id: _newId(now), name: '${original.name} (Copy)',
        length: original.length, width: original.width, bhk: original.bhk,
        floors: original.floors, facing: original.facing, brief: original.brief,
        createdAt: now, updatedAt: now),
      ..._projects,
    ];
  });

  Future<void> deleteProject(String id) =>
      _mutate(() => _projects.where((project) => project.id != id).toList());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
