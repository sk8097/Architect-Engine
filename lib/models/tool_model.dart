class ToolCategory {
  final String id;
  final String translationKey;
  final String icon;
  const ToolCategory({required this.id, required this.translationKey, required this.icon});
}

class ToolModel {
  final int id;
  final String category;
  final String? mainCategory; // Quantity | Area & Volume | Converter | Study & Quiz
  final String? subCategory; // Building Construction | Infrastructure | MEP | General
  final String? subSubCategory; // Quantity | Bonds | Closer Quantity | Shapes | Concrete | Steel
  final String icon;
  final String name;
  final String description;
  final bool isWorking;
  final String? advanceFormula;
  final String? refLink;
  final String? unit;
  final bool isNew;

  const ToolModel({
    required this.id,
    required this.category,
    this.mainCategory,
    this.subCategory,
    this.subSubCategory,
    required this.icon,
    required this.name,
    required this.description,
    required this.isWorking,
    this.advanceFormula,
    this.refLink,
    this.unit,
    this.isNew = false,
  });
}