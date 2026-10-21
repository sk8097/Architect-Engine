import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];

  List<ProjectModel> get projects => _projects;
  bool get hasProjects => _projects.isNotEmpty;

  ProjectProvider() {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('ae_projects_v1') ?? [];
    _projects = jsonList.map((e) => ProjectModel.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _projects.map((e) => e.toJson()).toList();
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
    final now = DateTime.now();
    final newProject = ProjectModel(
      id: 'p_${now.millisecondsSinceEpoch}',
      name: name,
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
    final index = _projects.findIndex((p) => p.id == id);
    if (index != -1) {
      _projects[index].name = name;
      _projects[index].length = length;
      _projects[index].width = width;
      _projects[index].bhk = bhk;
      _projects[index].floors = floors;
      _projects[index].facing = facing;
      _projects[index].updatedAt = DateTime.now();
      notifyListeners();
      await _saveProjects();
    }
  }

  Future<void> duplicateProject(String id) async {
    final original = _projects.firstWhere((p) => p.id == id);
    final now = DateTime.now();
    final copy = ProjectModel(
      id: 'p_${now.millisecondsSinceEpoch}',
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
    _projects.removeWhere((p) => p.id == id);
    notifyListeners();
    await _saveProjects();
  }
}
