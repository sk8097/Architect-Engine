import 'dart:convert';

class ProjectModel {
  final String id;
  String name;
  double length;
  double width;
  String bhk;
  String floors;
  String facing;
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
    required this.createdAt,
    required this.updatedAt,
  });

  double get areaSqFt => length * width;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'length': length,
      'width': width,
      'bhk': bhk,
      'floors': floors,
      'facing': facing,
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
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory ProjectModel.fromJson(String source) => ProjectModel.fromMap(json.decode(source));
}
