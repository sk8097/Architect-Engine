import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  int _corruptProjectCount = 0;

  List<ProjectModel> get projects => List.unmodifiable(_projects);
  bool get hasProjects => _projects.isNotEmpty;
  int get corruptProjectCount => _corruptProjectCount;

  ProjectProvider() {
    _loadProjects();
  }

  String _newProjectId() => 'p_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('ae_projects_v1') ?? [];
      final loaded = <ProjectModel>[];
      _corruptProjectCount = 0;
      for (final entry in stored) {
        try {
          final project = ProjectModel.fromJson(entry);
          if (project.id.isEmpty || project.length <= 0 || project.width <= 0) {
            _corruptProjectCount++;
            continue;
          }
          loaded.add(project);
        } catch (_) {
          _corruptProjectCount++;
        }
      }
      _projects = loaded;
    } catch (error) {
      debugPrint('Project storage could not be loaded: $error');
      _projects = [];
    }
    notifyListeners();
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _projects.map((project) => project.toJson()).toList();
    await prefs.setStringList('ae_projects_v1', jsonList);
  }

  Future<void> addProject({
    required String name,
    required double length,
    required double width,
    required String bhk,
    required String floors,
    required String facing,
  }) async {
    if (name.trim().isEmpty || length <= 0 || width <= 0) {
      throw ArgumentError('Project name and positive plot dimensions are required.');
    }
    final now = DateTime.now();
    final newProject = ProjectModel(
      id: _newProjectId(),
      name: name.trim(),
      length: length,
      width: width,
      bhk: bhk,
      floors: floors,
      facing: facing,
      createdAt: now,
      updatedAt: now,
    );
    _projects.insert(0, newProject);
    notifyListeners();
    await _saveProjects();
  }

  Future<void> updateProject({
    required String id,
    required String name,
    required double length,
    required double width,
    required String bhk,
    required String floors,
    required String facing,
  }) async {
    if (name.trim().isEmpty || length <= 0 || width <= 0) {
      throw ArgumentError('Project name and positive plot dimensions are required.');
    }
    final index = _projects.indexWhere((project) => project.id == id);
    if (index == -1) return;
    final project = _projects[index];
    project
      ..name = name.trim()
      ..length = length
      ..width = width
      ..bhk = bhk
      ..floors = floors
      ..facing = facing
      ..updatedAt = DateTime.now();
    notifyListeners();
    await _saveProjects();
  }

  Future<void> duplicateProject(String id) async {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index == -1) return;
    final original = _projects[index];
    final now = DateTime.now();
    final copy = ProjectModel(
      id: _newProjectId(),
      name: '${original.name} (Copy)',
      length: original.length,
      width: original.width,
      bhk: original.bhk,
      floors: original.floors,
      facing: original.facing,
      createdAt: now,
      updatedAt: now,
    );
    _projects.insert(0, copy);
    notifyListeners();
    await _saveProjects();
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((project) => project.id == id);
    notifyListeners();
    await _saveProjects();
  }
}
