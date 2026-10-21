class ToolModel {
  final int id;
  final String category;
  final String icon;
  final String name;
  final String description;
  final bool isWorking;

  const ToolModel({
    required this.id,
    required this.category,
    required this.icon,
    required this.name,
    required this.description,
    this.isWorking = true,
  });
}

class ToolCategory {
  final String id;
  final String translationKey;
  final String icon;

  const ToolCategory({
    required this.id,
    required this.translationKey,
    required this.icon,
  });
}
