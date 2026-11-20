import 'dart:convert';
import 'project_brief.dart';

class ProjectModel {
  final String id;
  String name;
  double length;
  double width;
  String bhk;
  String floors;
  String facing;
  ProjectBrief? brief;
  DateTime createdAt;
  DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.length,
    required this.width,
    required this.bhk,
    required this.floors,
    required this.facing,
    this.brief,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasPlotDimensions => width > 0 && length > 0;

  double get areaSqFt => length * width;

  String get description => [
        if (brief?.typeLabel != null) brief!.typeLabel!,
        if (bhk.isNotEmpty) bhk,
        floors,
        if (facing != 'Not decided') '$facing Facing',
      ].join(' • ');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'length': brief?.taxonomy != null && !hasPlotDimensions ? null : length,
      'width': brief?.taxonomy != null && !hasPlotDimensions ? null : width,
      'bhk': bhk,
      'floors': floors,
      'facing': facing,
      if (brief != null) 'brief': brief!.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      length: (map['length'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      bhk: map['bhk'] ?? '2 BHK',
      floors: map['floors'] ?? 'Ground floor',
      facing: map['facing'] ?? 'North',
      brief: ProjectBrief.fromMap(map['brief']),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory ProjectModel.fromJson(String source) => ProjectModel.fromMap(json.decode(source));
}
