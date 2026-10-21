import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// 1. APP COLORS & THEMES
// ==========================================


class AppColors {
  // Dark Theme Palette (Default)
  static const Color darkBg = Color(0xFF0A1128);
  static const Color darkCard = Color(0xFF131C35);
  static const Color darkPrimary = Color(0xFFE5B05C); // Gold accent
  static const Color darkTextMain = Color(0xFFFFFFFF);
  static const Color darkTextSub = Color(0xFFA0AEC0);
  static const Color darkBorder = Color(0x33E5B05C);
  static const Color darkIconBg = Color(0xFF1E293B);
  static const Color darkInput = Color(0xFF1E293B);
  static const Color darkGlow = Color(0xFFE5B05C);

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF2563EB); // Royal Blue accent
  static const Color lightTextMain = Color(0xFF0F172A);
  static const Color lightTextSub = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightIconBg = Color(0xFFE0E7FF);
  static const Color lightInput = Color(0xFFF1F5F9);
  static const Color lightGlow = Color(0xFF38BDF8);

  // Status badges
  static const Color statusAvailableBg = Color(0x2622C55E);
  static const Color statusAvailableText = Color(0xFF22C55E);
  static const Color statusProgressBg = Color(0x263B82F6);
  static const Color statusProgressText = Color(0xFF3B82F6);
  static const Color statusPlannedBg = Color(0x26E5B05C);
  static const Color statusPlannedText = Color(0xFFE5B05C);
}






class AppThemes {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkTextMain,
    ),
    cardColor: AppColors.darkCard,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.darkTextMain,
      displayColor: AppColors.darkTextMain,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.darkTextMain,
      elevation: 0,
      centerTitle: false,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightTextMain,
    ),
    cardColor: AppColors.lightCard,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: AppColors.lightTextMain,
      displayColor: AppColors.lightTextMain,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBg,
      foregroundColor: AppColors.lightTextMain,
      elevation: 0,
      centerTitle: false,
    ),
  );
}


// ==========================================
// 2. DATA MODELS
// ==========================================


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


class DesignModule {
  final int id;
  final String icon;
  final String key;
  final String status; // 'available', 'progress', 'planned'
  final bool isFullCard;

  const DesignModule({
    required this.id,
    required this.icon,
    required this.key,
    required this.status,
    this.isFullCard = false,
  });
}

class ProfessionalModule {
  final int id;
  final String icon;
  final String key;
  final String status;
  final String fullDescription;
  final List<String> uses;
  final String screenDesign;

  const ProfessionalModule({
    required this.id,
    required this.icon,
    required this.key,
    required this.status,
    required this.fullDescription,
    required this.uses,
    required this.screenDesign,
  });
}


class AppNotification {
  final String id;
  final String type; // 'payment', 'design', 'alert', 'info', 'success'
  final String title;
  final String message;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      type: map['type'] ?? 'info',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      time: DateTime.tryParse(map['time'] ?? '') ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}


// ==========================================
// 3. STATIC DATASETS (168 TOOLS, VASTU, DESIGN, CAD)
// ==========================================


class ToolsData {
  static const List<ToolCategory> categories = [
    ToolCategory(id: 'all', translationKey: 'All Tools', icon: '📦'),
    ToolCategory(id: 'fav', translationKey: 'Favorites', icon: '⭐'),
    ToolCategory(id: 'measure', translationKey: 'Measurement', icon: '📏'),
    ToolCategory(id: 'arch', translationKey: 'Architecture', icon: '📐'),
    ToolCategory(id: 'const', translationKey: 'Construction', icon: '👷'),
    ToolCategory(id: 'mat', translationKey: 'Materials', icon: '🧱'),
    ToolCategory(id: 'boq', translationKey: 'BOQ & Takeoff', icon: '📋'),
    ToolCategory(id: 'cost', translationKey: 'Cost & Budget', icon: '💰'),
    ToolCategory(id: 'slope', translationKey: 'Slopes & Levels', icon: '📉'),
    ToolCategory(id: 'struct', translationKey: 'Structural', icon: '🏗️'),
    ToolCategory(id: 'elec', translationKey: 'Electrical', icon: '⚡'),
    ToolCategory(id: 'plumb', translationKey: 'Plumbing', icon: '🚿'),
    ToolCategory(id: 'cad', translationKey: 'Drafting & CAD', icon: '✏️'),
    ToolCategory(id: 'math', translationKey: 'Math Utilities', icon: '🧮'),
    ToolCategory(id: 'site', translationKey: 'Site Logs', icon: '📔'),
  ];

  static const List<ToolModel> allTools = [
    ToolModel(id: 1, category: 'measure', icon: '📏', name: 'Length & Distance', description: 'Convert length units', isWorking: true),
    ToolModel(id: 2, category: 'measure', icon: '📐', name: 'Area Calculator', description: 'Rect/Tri/Circle', isWorking: true),
    ToolModel(id: 3, category: 'measure', icon: '🔲', name: 'Perimeter', description: 'Perimeter of shapes', isWorking: true),
    ToolModel(id: 4, category: 'measure', icon: '📦', name: 'Volume', description: 'Volume of 3D shapes', isWorking: true),
    ToolModel(id: 5, category: 'measure', icon: '🎁', name: 'Surface Area', description: 'Total surface area', isWorking: true),
    ToolModel(id: 6, category: 'measure', icon: '📐', name: 'Drawing Scale', description: 'Scale to real', isWorking: true),
    ToolModel(id: 7, category: 'measure', icon: '📊', name: 'Dimension Calc', description: 'Repeat dimensions', isWorking: true),
    ToolModel(id: 8, category: 'measure', icon: '📉', name: 'Slope & Gradient', description: 'Rise/run to %', isWorking: true),
    ToolModel(id: 9, category: 'measure', icon: '📏', name: 'Level Difference', description: 'Survey level', isWorking: true),
    ToolModel(id: 10, category: 'measure', icon: '📐', name: 'Angle Calc', description: 'Trigonometry', isWorking: true),
    ToolModel(id: 11, category: 'measure', icon: '📍', name: 'Coordinate Distance', description: 'Two-point', isWorking: true),
    ToolModel(id: 12, category: 'measure', icon: '📝', name: 'Measurement Sheet', description: 'Log measurements', isWorking: true),
    ToolModel(id: 13, category: 'measure', icon: '📊', name: 'Measurement Summary', description: 'Grouped totals', isWorking: true),
    ToolModel(id: 14, category: 'arch', icon: '🚪', name: 'Room Area', description: 'Room-wise area', isWorking: true),
    ToolModel(id: 15, category: 'arch', icon: '🏠', name: 'Floor Area', description: 'Sum room areas', isWorking: true),
    ToolModel(id: 16, category: 'arch', icon: '🛋️', name: 'Carpet Area', description: 'Usable area', isWorking: true),
    ToolModel(id: 17, category: 'arch', icon: '🏢', name: 'Built-up Area', description: 'Carpet+walls', isWorking: true),
    ToolModel(id: 18, category: 'arch', icon: '📐', name: 'Plot Coverage', description: 'Coverage %', isWorking: true),
    ToolModel(id: 19, category: 'arch', icon: '📊', name: 'FSI / FAR', description: 'Floor space index', isWorking: true),
    ToolModel(id: 20, category: 'arch', icon: '🧱', name: 'Wall Area', description: 'Wall-openings', isWorking: true),
    ToolModel(id: 21, category: 'arch', icon: '🚪', name: 'Door & Window', description: 'Openings list', isWorking: true),
    ToolModel(id: 22, category: 'arch', icon: '🪜', name: 'Staircase', description: 'Riser/tread count', isWorking: true),
    ToolModel(id: 23, category: 'arch', icon: '📐', name: 'Ramp Slope', description: 'Ramp gradient', isWorking: true),
    ToolModel(id: 24, category: 'arch', icon: '🚗', name: 'Parking Area', description: 'Bay area', isWorking: true),
    ToolModel(id: 25, category: 'arch', icon: '📋', name: 'Space Planning', description: 'Allocation', isWorking: true),
    ToolModel(id: 26, category: 'arch', icon: '📝', name: 'Room Schedule', description: 'Room+volume', isWorking: true),
    ToolModel(id: 27, category: 'arch', icon: '🏢', name: 'Floor-wise Area', description: 'Floor totals', isWorking: true),
    ToolModel(id: 28, category: 'const', icon: '⛏️', name: 'Excavation', description: 'Volume', isWorking: true),
    ToolModel(id: 29, category: 'const', icon: '🚜', name: 'Earthwork', description: 'Cut/fill', isWorking: true),
    ToolModel(id: 30, category: 'const', icon: '🪨', name: 'PCC', description: 'PCC volume', isWorking: true),
    ToolModel(id: 31, category: 'const', icon: '🏗️', name: 'RCC', description: 'RCC volume', isWorking: true),
    ToolModel(id: 32, category: 'const', icon: '🧱', name: 'Slab Concrete', description: 'Slab vol', isWorking: true),
    ToolModel(id: 33, category: 'const', icon: '📏', name: 'Beam Concrete', description: 'Beam vol', isWorking: true),
    ToolModel(id: 34, category: 'const', icon: '🏛️', name: 'Column Concrete', description: 'Column vol', isWorking: true),
    ToolModel(id: 35, category: 'const', icon: '⬛', name: 'Footing Concrete', description: 'Footing vol', isWorking: true),
    ToolModel(id: 36, category: 'const', icon: '🧱', name: 'Brickwork', description: 'Bricks+mortar', isWorking: true),
    ToolModel(id: 37, category: 'const', icon: '🧊', name: 'Blockwork', description: 'Block count', isWorking: true),
    ToolModel(id: 38, category: 'const', icon: '🥣', name: 'Mortar', description: 'Mortar vol', isWorking: true),
    ToolModel(id: 39, category: 'const', icon: '🎨', name: 'Plastering', description: 'Plaster vol', isWorking: true),
    ToolModel(id: 40, category: 'const', icon: '🔲', name: 'Flooring', description: 'Floor+waste', isWorking: true),
    ToolModel(id: 41, category: 'const', icon: '⬜', name: 'Tile Calc', description: 'Tile count', isWorking: true),
    ToolModel(id: 42, category: 'const', icon: '📏', name: 'Skirting', description: 'Skirting len', isWorking: true),
    ToolModel(id: 43, category: 'const', icon: '🖌️', name: 'Painting', description: 'Paint litres', isWorking: true),
    ToolModel(id: 44, category: 'const', icon: '🎨', name: 'Primer & Putty', description: 'Primer/putty', isWorking: true),
    ToolModel(id: 45, category: 'const', icon: '💧', name: 'Waterproofing', description: 'Waterproof', isWorking: true),
    ToolModel(id: 46, category: 'const', icon: '🏠', name: 'Roofing', description: 'Roof area', isWorking: true),
    ToolModel(id: 47, category: 'const', icon: '🔄', name: 'Backfilling', description: 'Backfill', isWorking: true),
    ToolModel(id: 48, category: 'const', icon: '🔲', name: 'Shuttering', description: 'Formwork', isWorking: true),
    ToolModel(id: 49, category: 'const', icon: '📦', name: 'Concrete Wastage', description: 'Base+waste%', isWorking: true),
    ToolModel(id: 50, category: 'const', icon: '🗑️', name: 'Material Wastage', description: 'Base+wastage', isWorking: true),
    ToolModel(id: 51, category: 'mat', icon: '🏗️', name: 'Cement Calc', description: 'Cement bags', isWorking: true),
    ToolModel(id: 52, category: 'mat', icon: '⏳', name: 'Sand Calc', description: 'Sand volume', isWorking: true),
    ToolModel(id: 53, category: 'mat', icon: '🪨', name: 'Aggregate Calc', description: 'Aggregate vol', isWorking: true),
    ToolModel(id: 54, category: 'mat', icon: '🏗️', name: 'Concrete Material', description: 'Cem+sand+agg', isWorking: true),
    ToolModel(id: 55, category: 'mat', icon: '🥣', name: 'Mortar Material', description: 'Cem+sand', isWorking: true),
    ToolModel(id: 56, category: 'mat', icon: '🧱', name: 'Brick Material', description: 'Bricks+5%', isWorking: true),
    ToolModel(id: 57, category: 'mat', icon: '🧊', name: 'Block Material', description: 'Block count', isWorking: true),
    ToolModel(id: 58, category: 'mat', icon: '🔩', name: 'Steel Weight', description: 'Rebar weight', isWorking: true),
    ToolModel(id: 59, category: 'mat', icon: '📐', name: 'Reinforcement Qty', description: 'Bars+weight', isWorking: true),
    ToolModel(id: 60, category: 'mat', icon: '⬜', name: 'Tile Quantity', description: 'Tiles+boxes', isWorking: true),
    ToolModel(id: 61, category: 'mat', icon: '🖌️', name: 'Paint Material', description: 'Paint litres', isWorking: true),
    ToolModel(id: 62, category: 'mat', icon: '🎨', name: 'Primer Material', description: 'Primer litres', isWorking: true),
    ToolModel(id: 63, category: 'mat', icon: '🎨', name: 'Putty Material', description: 'Putty kg', isWorking: true),
    ToolModel(id: 64, category: 'mat', icon: '🔲', name: 'Flooring Material', description: 'Flooring+5%', isWorking: true),
    ToolModel(id: 65, category: 'mat', icon: '🏠', name: 'Roofing Material', description: 'Sheets count', isWorking: true),
    ToolModel(id: 66, category: 'mat', icon: '💧', name: 'Waterproof Material', description: 'Product vol', isWorking: true),
    ToolModel(id: 67, category: 'mat', icon: '📊', name: 'Material Consumption', description: 'Qty×rate', isWorking: true),
    ToolModel(id: 68, category: 'mat', icon: '🗑️', name: 'Material Wastage 2', description: 'Base+%', isWorking: true),
    ToolModel(id: 69, category: 'boq', icon: '📋', name: 'Quantity Takeoff', description: 'Gross-deduct', isWorking: true),
    ToolModel(id: 70, category: 'boq', icon: '📊', name: 'Item-wise Qty', description: 'Item totals', isWorking: true),
    ToolModel(id: 71, category: 'boq', icon: '🏠', name: 'Room-wise Qty', description: 'Room totals', isWorking: true),
    ToolModel(id: 72, category: 'boq', icon: '🏢', name: 'Floor-wise Qty', description: 'Floor totals', isWorking: true),
    ToolModel(id: 73, category: 'boq', icon: '📝', name: 'Material Summary', description: 'Consolidated', isWorking: true),
    ToolModel(id: 74, category: 'boq', icon: '📔', name: 'Measurement Book', description: 'Site measurements', isWorking: true),
    ToolModel(id: 75, category: 'boq', icon: '📊', name: 'Quantity Abstract', description: 'Abstract', isWorking: true),
    ToolModel(id: 76, category: 'boq', icon: '💰', name: 'BOQ Builder', description: 'Item+rate+tax', isWorking: true),
    ToolModel(id: 77, category: 'boq', icon: '📚', name: 'BOQ Item Library', description: 'Standard items', isWorking: true),
    ToolModel(id: 78, category: 'boq', icon: '⚖️', name: 'BOQ Comparison', description: 'Original vs revised', isWorking: true),
    ToolModel(id: 79, category: 'boq', icon: '📝', name: 'BOQ Revision', description: 'Version tracking', isWorking: true),
    ToolModel(id: 80, category: 'boq', icon: '📤', name: 'BOQ Export', description: 'CSV/XLSX/PDF', isWorking: true),
    ToolModel(id: 81, category: 'cost', icon: '💰', name: 'Material Cost', description: 'Qty×rate', isWorking: true),
    ToolModel(id: 82, category: 'cost', icon: '👷', name: 'Labour Cost', description: 'Workers×days×wage', isWorking: true),
    ToolModel(id: 83, category: 'cost', icon: '🚜', name: 'Equipment Cost', description: 'Hrs×rental', isWorking: true),
    ToolModel(id: 84, category: 'cost', icon: '📊', name: 'Rate Analysis', description: 'Direct+overhead', isWorking: true),
    ToolModel(id: 85, category: 'cost', icon: '🏗️', name: 'Construction Cost', description: 'Total+tax', isWorking: true),
    ToolModel(id: 86, category: 'cost', icon: '🏢', name: 'Floor-wise Cost', description: 'Level-wise', isWorking: true),
    ToolModel(id: 87, category: 'cost', icon: '🏠', name: 'Room-wise Cost', description: 'Room-wise', isWorking: true),
    ToolModel(id: 88, category: 'cost', icon: '📐', name: 'Cost per Sq.Ft', description: 'Total÷area', isWorking: true),
    ToolModel(id: 89, category: 'cost', icon: '📐', name: 'Cost per Sq.M', description: 'Total÷area', isWorking: true),
    ToolModel(id: 90, category: 'cost', icon: '📊', name: 'Budget Planner', description: 'Allocation', isWorking: true),
    ToolModel(id: 91, category: 'cost', icon: '⚖️', name: 'Budget vs Estimate', description: 'Variance %', isWorking: true),
    ToolModel(id: 92, category: 'cost', icon: '🛡️', name: 'Contingency', description: 'Safety reserve', isWorking: true),
    ToolModel(id: 93, category: 'cost', icon: '🧾', name: 'Tax Calc', description: 'GST/levy', isWorking: true),
    ToolModel(id: 94, category: 'cost', icon: '📄', name: 'Quotation Builder', description: 'Proposal', isWorking: true),
    ToolModel(id: 95, category: 'cost', icon: '📊', name: 'Project Estimate', description: 'Master', isWorking: true),
    ToolModel(id: 96, category: 'slope', icon: '📉', name: 'Slope Calc', description: 'Rise/run to %', isWorking: true),
    ToolModel(id: 97, category: 'slope', icon: '📐', name: 'Gradient Calc', description: '1 in X', isWorking: true),
    ToolModel(id: 98, category: 'slope', icon: '📏', name: 'Level Difference', description: 'Levels comparison', isWorking: true),
    ToolModel(id: 99, category: 'slope', icon: '⬆️', name: 'Rise & Fall', description: 'Survey readings', isWorking: true),
    ToolModel(id: 100, category: 'slope', icon: '⛏️', name: 'Cut & Fill', description: 'Earthwork', isWorking: true),
    ToolModel(id: 101, category: 'slope', icon: '🛣️', name: 'Road Gradient', description: 'Highway slope', isWorking: true),
    ToolModel(id: 102, category: 'slope', icon: '💧', name: 'Drainage Gradient', description: 'Pipe slope', isWorking: true),
    ToolModel(id: 103, category: 'slope', icon: '📐', name: 'Cross-Section Area', description: 'Profile area', isWorking: true),
    ToolModel(id: 104, category: 'slope', icon: '📦', name: 'Earthwork Volume', description: 'Volume sections', isWorking: true),
    ToolModel(id: 105, category: 'slope', icon: '📍', name: 'Chainage & Offset', description: 'Alignment', isWorking: true),
    ToolModel(id: 106, category: 'slope', icon: '🧭', name: 'Survey Calc', description: 'Coordinate geo', isWorking: true),
    ToolModel(id: 107, category: 'slope', icon: '🧱', name: 'Retaining Wall', description: 'Wall volume', isWorking: true),
    ToolModel(id: 108, category: 'struct', icon: '📏', name: 'Beam Calc', description: 'Beam geometry', isWorking: true),
    ToolModel(id: 109, category: 'struct', icon: '🏛️', name: 'Column Calc', description: 'Column volume', isWorking: true),
    ToolModel(id: 110, category: 'struct', icon: '🧱', name: 'Slab Calc', description: 'Slab volume', isWorking: true),
    ToolModel(id: 111, category: 'struct', icon: '⬛', name: 'Footing Calc', description: 'Footing volume', isWorking: true),
    ToolModel(id: 112, category: 'struct', icon: '🔩', name: 'Reinforcement Qty', description: 'Bar count', isWorking: true),
    ToolModel(id: 113, category: 'struct', icon: '⚖️', name: 'Steel Weight', description: 'Rebar weight', isWorking: true),
    ToolModel(id: 114, category: 'struct', icon: '📋', name: 'Bar Bending Schedule', description: 'BBS', isWorking: true),
    ToolModel(id: 115, category: 'struct', icon: '✂️', name: 'Rebar Cutting Length', description: 'Cutting len', isWorking: true),
    ToolModel(id: 116, category: 'struct', icon: '🔗', name: 'Stirrup Qty', description: 'Tie count', isWorking: true),
    ToolModel(id: 117, category: 'struct', icon: '📊', name: 'Concrete Summary', description: 'Project concrete', isWorking: true),
    ToolModel(id: 118, category: 'struct', icon: '📊', name: 'Reinforcement Summary', description: 'Project steel', isWorking: true),
    ToolModel(id: 119, category: 'elec', icon: '💡', name: 'Electrical Points', description: 'Lights/sockets', isWorking: true),
    ToolModel(id: 120, category: 'elec', icon: '💡', name: 'Lighting Schedule', description: 'Fixture+watt', isWorking: true),
    ToolModel(id: 121, category: 'elec', icon: '⚡', name: 'Connected Load', description: 'Total load', isWorking: true),
    ToolModel(id: 122, category: 'elec', icon: '🔌', name: 'Circuit Load', description: 'Current (A)', isWorking: true),
    ToolModel(id: 123, category: 'elec', icon: '🪢', name: 'Cable Length', description: 'Wire length', isWorking: true),
    ToolModel(id: 124, category: 'elec', icon: '📋', name: 'Electrical Material', description: 'Hardware list', isWorking: true),
    ToolModel(id: 125, category: 'elec', icon: '💰', name: 'Electrical Cost', description: 'Material+labour', isWorking: true),
    ToolModel(id: 126, category: 'plumb', icon: '🚽', name: 'Fixture Schedule', description: 'WC/basin', isWorking: true),
    ToolModel(id: 127, category: 'plumb', icon: '🪈', name: 'Pipe Length', description: 'Pipe run', isWorking: true),
    ToolModel(id: 128, category: 'plumb', icon: '🔗', name: 'Pipe & Fitting', description: 'Fittings', isWorking: true),
    ToolModel(id: 129, category: 'plumb', icon: '💧', name: 'Water Demand', description: 'L/day', isWorking: true),
    ToolModel(id: 130, category: 'plumb', icon: '🛢️', name: 'Water Tank Vol', description: 'Capacity', isWorking: true),
    ToolModel(id: 131, category: 'plumb', icon: '📉', name: 'Drainage Gradient', description: 'Pipe slope', isWorking: true),
    ToolModel(id: 132, category: 'plumb', icon: '📋', name: 'Plumbing Material', description: 'Supply list', isWorking: true),
    ToolModel(id: 133, category: 'plumb', icon: '💰', name: 'Plumbing Cost', description: 'Financial', isWorking: true),
    ToolModel(id: 134, category: 'cad', icon: '📐', name: 'Drawing Scale', description: 'Blueprint', isWorking: true),
    ToolModel(id: 135, category: 'cad', icon: '📏', name: 'Dimension Calc', description: 'Diagonal', isWorking: true),
    ToolModel(id: 136, category: 'cad', icon: '✏️', name: 'Annotation Tools', description: 'Text labels', isWorking: true),
    ToolModel(id: 137, category: 'cad', icon: '📚', name: 'Layer Management', description: 'Layer props', isWorking: true),
    ToolModel(id: 138, category: 'cad', icon: '📄', name: 'Sheet Setup', description: 'A3/A4', isWorking: true),
    ToolModel(id: 139, category: 'cad', icon: '📋', name: 'Title Block', description: 'Project info', isWorking: true),
    ToolModel(id: 140, category: 'cad', icon: '📝', name: 'Revision Manager', description: 'Change tracking', isWorking: true),
    ToolModel(id: 141, category: 'cad', icon: '✅', name: 'Drawing Validation', description: 'Rule checks', isWorking: true),
    ToolModel(id: 142, category: 'cad', icon: '👁️', name: 'Drawing Preview', description: 'Vector view', isWorking: true),
    ToolModel(id: 143, category: 'cad', icon: '🔄', name: 'DXF Import/Export', description: 'CAD conversion', isWorking: true),
    ToolModel(id: 144, category: 'math', icon: '🧮', name: 'Basic Calculator', description: 'Arithmetic', isWorking: true),
    ToolModel(id: 145, category: 'math', icon: '%', name: 'Percentage Calc', description: 'Percentage', isWorking: true),
    ToolModel(id: 146, category: 'math', icon: '⚖️', name: 'Ratio Calc', description: 'Ratio simplify', isWorking: true),
    ToolModel(id: 147, category: 'math', icon: '📐', name: 'Proportion Calc', description: 'Missing value', isWorking: true),
    ToolModel(id: 148, category: 'math', icon: '📊', name: 'Average Calc', description: 'Mean', isWorking: true),
    ToolModel(id: 149, category: 'math', icon: '🔢', name: 'Decimal to Fraction', description: 'Conversion', isWorking: true),
    ToolModel(id: 150, category: 'math', icon: '📅', name: 'Date Difference', description: 'Days', isWorking: true),
    ToolModel(id: 151, category: 'math', icon: '⏱️', name: 'Project Duration', description: 'Working days', isWorking: true),
    ToolModel(id: 152, category: 'math', icon: '💾', name: 'Saved Calculations', description: 'Storage', isWorking: true),
    ToolModel(id: 153, category: 'math', icon: '📔', name: 'Calculation History', description: 'Audit', isWorking: true),
    ToolModel(id: 154, category: 'math', icon: '📝', name: 'Site Notes', description: 'Observations', isWorking: true),
    ToolModel(id: 155, category: 'math', icon: '📤', name: 'Copy & Share', description: 'Clipboard', isWorking: true),
    ToolModel(id: 156, category: 'math', icon: '📄', name: 'Export Reports', description: 'CSV/PDF', isWorking: true),
    ToolModel(id: 157, category: 'site', icon: '👥', name: 'Stakeholder Directory', description: 'Contacts', isWorking: true),
    ToolModel(id: 158, category: 'site', icon: '📝', name: 'Stakeholder Notes', description: 'Trade log', isWorking: true),
    ToolModel(id: 159, category: 'site', icon: '📔', name: 'Daily Progress', description: 'Weather/labor', isWorking: true),
    ToolModel(id: 160, category: 'site', icon: '📦', name: 'Material Delivery', description: 'Delivery note', isWorking: true),
    ToolModel(id: 161, category: 'site', icon: '📋', name: 'Site Instruction', description: 'Change ticket', isWorking: true),
    ToolModel(id: 162, category: 'site', icon: '⚠️', name: 'Safety Incident', description: 'Safety record', isWorking: true),
    ToolModel(id: 163, category: 'site', icon: '🔧', name: 'Punch List', description: 'Snag items', isWorking: true),
    ToolModel(id: 164, category: 'site', icon: '👷', name: 'Labour Attendance', description: 'Wages', isWorking: true),
    ToolModel(id: 165, category: 'site', icon: '🤝', name: 'Client Meeting', description: 'Decision notes', isWorking: true),
    ToolModel(id: 166, category: 'site', icon: '🚜', name: 'Equipment Deployment', description: 'Custody', isWorking: true),
    ToolModel(id: 167, category: 'site', icon: '🎤', name: 'Voice Memo', description: 'Field notes', isWorking: true),
    ToolModel(id: 168, category: 'site', icon: '📤', name: 'Stakeholder Report', description: 'PDF/TXT/CSV', isWorking: true),
  ];
}




class DesignData {
  static const List<DesignModule> modules = [
    DesignModule(
      id: 1,
      icon: '📐',
      key: 'floor_plan',
      status: 'progress',
    ),
    DesignModule(
      id: 2,
      icon: '🏞️',
      key: 'site_plan',
      status: 'planned',
    ),
    DesignModule(
      id: 3,
      icon: '🏠',
      key: 'elevation',
      status: 'planned',
    ),
    DesignModule(
      id: 4,
      icon: '📉',
      key: 'section',
      status: 'planned',
    ),
    DesignModule(
      id: 5,
      icon: '📦',
      key: 'view_3d',
      status: 'planned',
    ),
    DesignModule(
      id: 6,
      icon: '🛋️',
      key: 'interior',
      status: 'planned',
    ),
    DesignModule(
      id: 7,
      icon: '🌳',
      key: 'landscape',
      status: 'planned',
    ),
    DesignModule(
      id: 8,
      icon: '🏗️',
      key: 'structural',
      status: 'planned',
    ),
    DesignModule(
      id: 9,
      icon: '⚡',
      key: 'electrical',
      status: 'planned',
    ),
    DesignModule(
      id: 10,
      icon: '🚿',
      key: 'plumbing',
      status: 'planned',
    ),
    DesignModule(
      id: 11,
      icon: '📋',
      key: 'coordinated_drawings',
      status: 'planned',
      isFullCard: true,
    ),
  ];

  static final Map<int, Map<String, String>> moduleDetails = {
    1: {
      'name': 'Floor Plan',
      'desc': 'Room layouts & architectural spatial arrangement',
      'full': 'Building ka primary architectural layout, room boundaries, dimensions, wall thickness, and door/window placements.',
    },
    2: {
      'name': 'Site Plan',
      'desc': 'Plot & site zoning and landscape coordinates',
      'full': 'Building ko poore plot aur surroundings mein position karna, setback distance, access roads, and North orientation.',
    },
    3: {
      'name': 'Elevation',
      'desc': 'Exterior views, facade treatments & levels',
      'full': 'Front, rear, and side exterior elevations showing architectural facade styling, sill/lintel heights, and floor levels.',
    },
    4: {
      'name': 'Section',
      'desc': 'Vertical cuts through building structural levels',
      'full': 'Building ke through vertical cut showing slab thickness, foundation depth, staircase headroom, and roof construction.',
    },
    5: {
      'name': '3D View',
      'desc': 'Spatial volumetric 3D representation',
      'full': '3D interactive massing, daylight simulation, and textured exterior/interior walkthrough representations.',
    },
    6: {
      'name': 'Interior',
      'desc': 'Spaces, furniture layouts & finishes',
      'full': 'Room-wise space planning, furniture clearances, false ceiling layouts, flooring materials, and finish schedules.',
    },
    7: {
      'name': 'Landscape',
      'desc': 'Outdoor design, paving & planting layout',
      'full': 'Outdoor hardscape and softscape design, driveway paving, garden zones, drainage channels, and exterior lighting.',
    },
    8: {
      'name': 'Structural',
      'desc': 'Structural engineering & frame coordination',
      'full': 'Column-beam grid layout, footing center lines, slab reinforcement schedules, and engineer design coordination.',
    },
    9: {
      'name': 'Electrical',
      'desc': 'Power conduits, fixtures & circuit loads',
      'full': 'Lighting points, power sockets, switchboard locations, conduit pathways, DB distribution, and connected load schedules.',
    },
    10: {
      'name': 'Plumbing',
      'desc': 'Water supply, drainage & sanitary lines',
      'full': 'Potable cold/hot water distribution, soil & waste drainage slope routes, inspection chambers, and overhead tank sizing.',
    },
    11: {
      'name': 'Coordinated Drawings & Documents',
      'desc': 'Drawing sets, revision control & multi-discipline coordination',
      'full': 'Integrated BIM coordination overlay preventing MEP vs Structural clashes, drawing register tracking, and revision approvals.',
    },
  };
}




class ProfessionalData {
  static const List<ProfessionalModule> modules = [
    ProfessionalModule(
      id: 1,
      icon: '🖥️',
      key: 'cad',
      status: 'progress',
      fullDescription: 'Precision drawing workspace with coordinates, grid, snap, object selection, move, copy, rotate, mirror, offset, trim, extend, align. Future DXF import/edit/export integration.',
      uses: [
        'Coordinates, grid and snap for millimeter-accurate placement',
        'Object selection, move, copy, rotate, mirror operations',
        'Offset, trim, extend, align geometry tools',
        'Direct measurement and supported entity modification',
        'Future DXF import, CAD layer editing, and export workflows'
      ],
      screenDesign: 'Dedicated vector canvas with coordinate display HUD, grid overlay toggle, snap indicators, and contextual drawing toolbar that adapts to selected tool.',
    ),
    ProfessionalModule(
      id: 2,
      icon: '✏️',
      key: 'draw_tools',
      status: 'progress',
      fullDescription: 'Line, polyline, rectangle, circle, arc, hatch, select, erase, duplicate, undo/redo and object properties. Context-sensitive drawing tools.',
      uses: [
        'Draw and modify precise 2D architectural shapes',
        'Context-sensitive tool activation based on active drawing type',
        'Object properties panel for stroke color, layer, line-type, and style',
        'Multi-level undo/redo for effortless mistake recovery',
        'Smart duplicate with polar or rectangular offset and mirror'
      ],
      screenDesign: 'Left toolbar with geometric shape tools, center zoomable canvas, and collapsible right-hand properties inspector. Bottom sheet for mobile controls.',
    ),
    ProfessionalModule(
      id: 3,
      icon: '📚',
      key: 'layers',
      status: 'planned',
      fullDescription: 'Layer create/rename/delete, visibility, lock/unlock, color, line type and lineweight. Architectural, structural, electrical and plumbing layers organization.',
      uses: [
        'Create and isolate separate layers per engineering discipline',
        'Toggle visibility and freeze/lock states effortlessly',
        'Set color, line type (dashed, continuous) and lineweight per layer',
        'Organize architectural, structural, electrical, and plumbing layers',
        'Filter layer tree by active discipline or phase'
      ],
      screenDesign: 'Layer manager bottom drawer with color swatch picker, eye visibility toggle, padlock icon, and discipline group headers.',
    ),
    ProfessionalModule(
      id: 4,
      icon: '📏',
      key: 'dimensions',
      status: 'planned',
      fullDescription: 'Linear, aligned, angular, radius and diameter dimensions; unit/precision settings; dimension styles and readable annotation placement.',
      uses: [
        'Add linear, aligned, angular, radius, and diameter dimensions',
        'Configure unit display (Metric/Imperial) and precision roundings',
        'Create and store reusable dimension styles for consistency',
        'Auto-place readable annotations at appropriate drawing scale',
        'Dynamic dimension editing with linked geometry updates'
      ],
      screenDesign: 'Dimension style dropdown selector, on-screen interactive dimension placement with smart snapping to endpoints and midpoints.',
    ),
    ProfessionalModule(
      id: 5,
      icon: '📝',
      key: 'annotations',
      status: 'planned',
      fullDescription: 'Text, room labels, notes, leaders, symbols, callouts, north arrows and drawing legends with text size and plotting scale control.',
      uses: [
        'Add rich text and room name/area stamps anywhere on the drawing',
        'Multi-line notes with leader arrows and custom pointers',
        'Place standard architectural symbols, callouts, and North arrows',
        'Fine-tune text heights for exact sheet plotting scales',
        'Generate and position auto-updating drawing legends'
      ],
      screenDesign: 'Annotation ribbon toolbar with text, leader, and symbol libraries. Rich-text editor overlay with font, size, and alignment sliders.',
    ),
    ProfessionalModule(
      id: 6,
      icon: '📋',
      key: 'templates',
      status: 'planned',
      fullDescription: 'Reusable drawing sheets, title blocks, standard layers, dimension styles, annotation presets and project templates.',
      uses: [
        'Save any project setup as a standard reusable organization template',
        'Apply ISO / Indian Standard title blocks to new drawing sheets',
        'Reuse discipline layers, dimension styles, and annotation presets',
        'Build project-specific templates for rapid onboarding',
        'Import and export template files across team members'
      ],
      screenDesign: 'Templates gallery featuring visual sheet previews, Save-as-Template modal, and template metadata configuration sheet.',
    ),
    ProfessionalModule(
      id: 7,
      icon: '⚙️',
      key: 'standards',
      status: 'planned',
      fullDescription: 'Configurable units, lineweights, text styles, symbols, layer naming and drawing conventions complying with national building codes.',
      uses: [
        'Set project default units (mm, cm, m, inches, feet) and precision',
        'Configure pen lineweights and drafting line styles',
        'Standardize architectural symbols and AIA / NBC layer naming',
        'Enforce consistent drafting standards across all project sheets',
        'Maintain jurisdiction-specific compliance guidelines separately'
      ],
      screenDesign: 'Tabbed standards inspector with Units, Lineweights, Typography, Symbols, and Layer Naming configurations.',
    ),
    ProfessionalModule(
      id: 8,
      icon: '⚡',
      key: 'productivity',
      status: 'planned',
      fullDescription: 'Recent tools, favorites, command history, shortcuts, repeat-last-command, quick properties and frequently used operations.',
      uses: [
        'Instant 1-tap access to recently used and pinned favorite tools',
        'Searchable command history audit log',
        'Comprehensive keyboard shortcuts and gesture accelerators',
        'Repeat last command with a single tap or spacebar',
        'Quick properties floating panel for high-velocity editing'
      ],
      screenDesign: 'Top horizontal recent tools ribbon, pinned quick-action toolbar, and customizable shortcut mapper screen.',
    ),
    ProfessionalModule(
      id: 9,
      icon: '📄',
      key: 'documentation',
      status: 'planned',
      fullDescription: 'Drawing register, sheet numbering, revision history, drawing notes, issue status, sheet composition and PDF/DXF export workflow.',
      uses: [
        'Maintain a master drawing register for the entire project',
        'Auto-number sheets (A-101, S-101, E-101) and track revision logs',
        'Record general drawing notes, approvals, and issue status',
        'Compose multi-view sheet layouts with viewports and scales',
        'Direct export to publication-grade vector PDF and editable DXF'
      ],
      screenDesign: 'Documentation workbench with tabs for Register, Sheet Layouts, Revisions, and Batch Export status cards.',
    ),
  ];
}


class VastuItem {
  final String title;
  final List<String> guidelines;

  const VastuItem({required this.title, required this.guidelines});
}

class VastuData {
  static const List<VastuItem> items = [
    VastuItem(
      title: '🚪 Main Entrance (Mukhya Dwar)',
      guidelines: [
        'Entrance should ideally face North, East, or North-East direction for prosperity and positive energy flow.',
        'The main door should always open inward (clockwise) rather than outward.',
        'Keep the entrance well-lit with warm illumination, clutter-free, and immaculately clean.',
        'Avoid positioning the main entrance directly facing a bathroom, cooking stove, or descending staircase.',
        'Adorn the entrance threshold with a clean nameplate, auspicious toran, or traditional rangoli.',
        'Ensure the door hinges are oiled regularly to prevent any creaking sounds.',
      ],
    ),
    VastuItem(
      title: '🍳 Kitchen (Rasoi)',
      guidelines: [
        'The primary kitchen must be situated in the South-East corner (governed by Agni Deva).',
        'The cooking platform should be oriented such that one faces East while cooking.',
        'The water sink and fire stove must never be placed adjacent to or directly opposite each other.',
        'Drinking water filters (RO) or clay pots should reside in the North-East section of the kitchen.',
        'Avoid locating the kitchen directly beneath or above a bathroom.',
        'Favorable wall shades for kitchens include warm peach, light green, or soft yellow.',
        'Keep the cooking stove safe from direct wind drafts from open windows.',
      ],
    ),
    VastuItem(
      title: '🛏️ Master Bedroom',
      guidelines: [
        'The master bedroom should be situated in the South-West corner of the home for stability and health.',
        'Position the bed so that sleeping heads point toward the South or East.',
        'Ensure that mirrors or reflective wardrobe doors do not reflect the sleeping person directly.',
        'Keep electronic chargers, routers, and screens at a distance from the bed.',
        'Opt for soothing earthy shades like cream, ivory, beige, or soft moss green.',
        'Refrain from keeping active water fountains or aquariums inside the bedroom.',
        'Heavy wardrobes and storage should ideally line the South or West walls.',
      ],
    ),
    VastuItem(
      title: '🛋️ Living Room (Hall)',
      guidelines: [
        'Living rooms thrive in the North, East, or North-East directions to foster social harmony.',
        'Heavy sofas and furniture should be anchored against the Southern and Western walls.',
        'Keep the North-East quadrant of the living hall open, light, and spotless.',
        'House electronic entertainment centers and TVs along the South-East wall.',
        'Seat family and esteemed guests facing East or North for uplifting conversations.',
        'Incorporate light, luminous colors on walls and airy, sheer drapery.',
        'Immediately discard broken ornaments, non-working clocks, or dried flowers.',
      ],
    ),
    VastuItem(
      title: '🚿 Bathroom & Sanitary',
      guidelines: [
        'Bathrooms are best positioned in the West or North-West direction.',
        'Strictly avoid bathrooms in the sacred North-East (Ishaan) corner of the home.',
        'Commode seats should be aligned facing North-South.',
        'Keep the bathroom door firmly closed at all times to seal in heavy energies.',
        'Immediately repair dripping faucets and leaky pipelines.',
        'Ensure generous ventilation with high exhaust fans and light, pastel tile choices.',
        'Never place mirrors reflecting the toilet commode.',
      ],
    ),
    VastuItem(
      title: '🕉️ Pooja Room (Mandir)',
      guidelines: [
        'The sacred Pooja room must always be positioned in the North-East (Ishaan corner).',
        'Idols and deities should face West or East, allowing worshippers to face East or North.',
        'Keep the mandir tranquil, uncluttered, and gracefully lit with pure white or warm brass tones.',
        'Never construct a pooja room inside a bedroom, beneath a staircase, or adjacent to toilets.',
        'Choose natural white marble, pure teakwood, or stone for the altar shrine.',
        'Avoid keeping chipped idols, cracked glass photos, or faded offerings.',
        'Kindle an authentic ghee or oil lamp every morning and evening for divine vitality.',
      ],
    ),
    VastuItem(
      title: '🏢 Staircase',
      guidelines: [
        'Staircases belong along the South, West, or South-West perimeters of the structure.',
        'Always design staircases to ascend in a clockwise direction.',
        'Never position a heavy staircase in the delicate North-East or the central Brahmasthan.',
        'Plan the total step count to an odd number (such as 15, 17, 19, or 21).',
        'Utilize the space beneath the stairs only for dry storage, never for pooja or restrooms.',
      ],
    ),
    VastuItem(
      title: '🌳 Outdoor & Garden',
      guidelines: [
        'Plant the sacred Tulsi (Holy Basil) plant in the North-East or East courtyard.',
        'Avoid planting towering, dense shade trees in the North-East quadrant.',
        'Plant tall, broad-canopied trees along the South and West boundaries for thermal insulation.',
        'A serene water fountain or reflective pond in the North-East is deeply auspicious.',
        'Avoid planting thorny cacti or milky-sap flora right near the main entry gate.',
      ],
    ),
    VastuItem(
      title: '💡 General Harmonization Rules',
      guidelines: [
        'Keep the exact geometric center of the floor plan (Brahmasthan) open and free of pillars.',
        'Maximize natural sunlit openings along East and North for health and positive vibes.',
        'Promptly repair peeling paint, damp patches, and broken tiles.',
        'Avoid stagnant, dark alcoves with gentle accent uplighting.',
        'Incorporate natural building materials like timber, terracotta, and stone wherever feasible.',
        'Fill your morning ambiance with tranquil instrumental melodies or Vedic chants.',
      ],
    ),
  ];
}


class TutorialItem {
  final String icon;
  final String title;
  final String subtitle;
  final String intro;
  final List<String> steps;
  final String tip;

  const TutorialItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.steps,
    required this.tip,
  });
}

class TutorialsData {
  static const List<TutorialItem> items = [
    TutorialItem(
      icon: '🚀',
      title: 'Getting Started with Architect Engine',
      subtitle: 'Learn the fundamentals of creating your first project',
      intro: 'Welcome to Architect Engine! Follow these quick steps to launch your first design project:',
      steps: [
        'Tap the "+ New Project" button located prominently on the Home dashboard.',
        'Input your real plot dimensions: Length and Width in feet or meters.',
        'Choose your room configuration (e.g. 2BHK, 3BHK, Custom) and number of floor levels.',
        'Specify your plot orientation (North, East, South, West) for auto-Vastu alignment.',
        'Choose your architectural styling: Modern Contemporary, Minimalist, Traditional, or Luxury.',
        'Set your target budget range to let the app calibrate recommended materials and finishes.',
        'Tap "Save Project" to store your project securely and unlock full drawing modules.',
      ],
      tip: 'Tip: For your initial test, start with a standard 30x40 or 40x60 ft rectangular plot.',
    ),
    TutorialItem(
      icon: '📐',
      title: 'Creating Architectural Floor Plans',
      subtitle: 'Spatial room layout planning and dimensioning',
      intro: 'A floor plan forms the bedrock of any building project. Here is how to plan it efficiently:',
      steps: [
        'Open the Design tab and select "Floor Plan" module.',
        'Verify your plot setbacks (front, rear, and side clearances as mandated by local bylaws).',
        'Place the living room and entryway in the North or East zones for natural daylight.',
        'Position the kitchen in South-East (Agni corner) and master bedroom in South-West.',
        'Define clear circulation corridors connecting rooms without wasted hallway space.',
        'Verify door swings and window ventilation points for every habitable room.',
        'Inspect the carpet area and built-up area totals calculated automatically.',
      ],
      tip: 'Rule of thumb: A comfortable 3BHK home typically spans between 1200 to 1800 sq.ft.',
    ),
    TutorialItem(
      icon: '📏',
      title: 'Mastering Unit Conversions',
      subtitle: 'Switch seamlessly between Metric and Imperial units',
      intro: 'Construction sites frequently juggle feet, inches, meters, and local land metrics:',
      steps: [
        'Navigate to Drawer → Unit Converter or open Tool #1 from the Tools tab.',
        'Select your conversion type: Length, Area, Volume, or Weight.',
        'Enter your quantity in the input field.',
        'Select the origin unit (e.g., Square Feet, Guntha, Gaj, Bigha, Acres, Square Meters).',
        'Observe instant real-time conversions without needing an internet connection.',
      ],
      tip: 'Standard conversions: 1 sq.m = 10.764 sq.ft | 1 Gaj = 9 sq.ft | 1 Guntha = 1089 sq.ft.',
    ),
    TutorialItem(
      icon: '🕉️',
      title: 'Applying Vastu Principles to Your Layout',
      subtitle: 'Ancient spatial orientation principles made easy',
      intro: 'Architect Engine features built-in directional guidelines for positive living:',
      steps: [
        'Confirm your plot cardinal direction using a smartphone compass or site survey.',
        'Main Door: Place in the auspicious fourth or fifth pada of North or East wall.',
        'Kitchen: Align the gas stove so you face East while preparing food.',
        'Master Bedroom: Keep in the South-West zone for health, peace, and longevity.',
        'Pooja Room: Set in North-East (Ishaan) and ensure no toilets share a wall with it.',
        'Staircase: Construct in South or West turning clockwise as you ascend.',
      ],
      tip: 'Refer to the comprehensive Vastu Guide section in the side drawer for room-by-room details.',
    ),
    TutorialItem(
      icon: '💾',
      title: 'Saving, Managing & Backing Up Projects',
      subtitle: 'Keep your work organized, secure, and accessible',
      intro: 'Every project you create is automatically indexed and preserved:',
      steps: [
        'All your creations appear directly under the "My Projects" section on Home.',
        'Tap any project card to open, review details, or update plot specifications.',
        'Use the "Duplicate" option to test alternative layouts without losing your baseline.',
        'Enable Cloud Sync to maintain cloud backups alongside local offline storage.',
        'Connect your Google Drive account for one-click cloud archiving.',
      ],
      tip: 'Naming tip: Give descriptive names like "Sharma Villa — 40x50 East Facing — R1".',
    ),
    TutorialItem(
      icon: '🎨',
      title: 'Personalizing Theme & Languages',
      subtitle: 'Dark mode, Light mode, and 5 Indian regional languages',
      intro: 'Tailor Architect Engine to match your personal working environment:',
      steps: [
        'Tap the moon/sun icon 🌗 in the top right header to instantly toggle between Dark and Light mode.',
        'Open Side Drawer → App Preferences → Theme to set your permanent preference.',
        'Open Side Drawer → Language to switch the interface language.',
        'Full UI translation is available in English, हिंदी, मराठी, ગુજરાતી, and தமிழ்.',
      ],
      tip: 'Dark mode is optimized for evening drafting sessions, saving battery on OLED displays.',
    ),
    TutorialItem(
      icon: '💰',
      title: 'Understanding Construction Cost & BOQ',
      subtitle: 'Estimation formulas, material quantities, and contractor quotes',
      intro: 'Estimate construction expenditure with realistic material ratios:',
      steps: [
        'Civil Construction Cost: Generally spans ₹1,500 to ₹2,500 per sq.ft based on grade.',
        'Finishing & Interiors: Accounts for ₹600 to ₹1,800 per sq.ft (flooring, sanitary, paint).',
        'Consultancy & Approvals: Municipality sanctions and architecture charges average 5% to 8%.',
        'Contingency Buffer: Always reserve 10% for material price variations and foundation surprises.',
        'Explore Tools 81–95 in the Tools tab for itemized rate analysis and cement/steel calculators.',
      ],
      tip: 'Always collect 3 detailed contractor quotations with specified material brands before starting.',
    ),
  ];
}


class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}

class FAQData {
  static const List<FAQItem> items = [
    FAQItem(
      question: 'Is Architect Engine free to use?',
      answer: 'Yes! The core tools, including the Unit Converter, Vastu Guide, Tutorials, Project Manager, and standard calculation utilities are completely free. Advanced CAD and AI rendering features will be part of the upcoming Pro tier.',
    ),
    FAQItem(
      question: 'How does the architectural design system work?',
      answer: 'The system uses parametric design rules combined with standard National Building Code (NBC) setbacks, room clearance ratios, and Vastu orientation algorithms to generate coordinated floor plans, elevations, and structural schematics.',
    ),
    FAQItem(
      question: 'Does the application work offline?',
      answer: 'Yes! All 168 calculation tools, unit converters, Vastu guides, tutorials, and local project management work 100% offline without any internet connection. Online access is only needed for cloud syncing and sharing.',
    ),
    FAQItem(
      question: 'Where are my projects and calculations saved?',
      answer: 'All projects, saved calculations, and notes are stored locally on your device in secure persistent storage. If you enable Cloud Sync or link your Google Drive, encrypted backups are created in your personal cloud.',
    ),
    FAQItem(
      question: 'Can I export my project drawings and estimates?',
      answer: 'Yes! The Export Center supports exporting project summary sheets as print-ready PDF files, CAD-ready drawing data, and CSV/Excel Bill of Quantities (BOQ) sheets.',
    ),
    FAQItem(
      question: 'How accurate are the material calculations and cost estimates?',
      answer: 'The formulas adhere strictly to standard civil engineering dry-volume constants (e.g. 1.54 for concrete dry-volume, 1.33 for mortar, 500 bricks/m³). However, actual market rates vary by city and brand, so always verify with local suppliers.',
    ),
    FAQItem(
      question: 'Are the design plans Vastu-compliant?',
      answer: 'Yes! By default, room layouts and directional orientations follow traditional Vastu Shastra guidelines (East/North entrances, South-East kitchens, South-West master bedrooms, and North-East pooja shrines).',
    ),
    FAQItem(
      question: 'Is my personal data and drawing information secure?',
      answer: 'Your data privacy is strictly protected. Your project records reside solely on your device unless you explicitly opt to sync with your private Google Drive. We do not sell or monetize personal data.',
    ),
    FAQItem(
      question: 'How can I contact technical support or request new features?',
      answer: 'You can email our engineering team directly at support@architectengine.app or use the feedback option inside the app. We actively welcome feedback from architects, contractors, and students.',
    ),
    FAQItem(
      question: 'Can I use this app on tablets and desktops?',
      answer: 'Yes! Architect Engine is built with responsive Flutter UI that smoothly adapts to smartphones, iPads, Android tablets, and desktop screen sizes.',
    ),
  ];
}


// ==========================================
// 4. STATE PROVIDERS
// ==========================================
class AppStateProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _currentLanguage = 'en';
  List<int> _favoriteToolIds = [];
  String _userName = 'Guest User';
  String _userEmail = '';
  String _userPhone = '';
  String _storageType = 'local';
  bool _gdriveConnected = false;
  String _gdriveEmail = '';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currentLanguage => _currentLanguage;
  List<int> get favoriteToolIds => _favoriteToolIds;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get storageType => _storageType;
  bool get gdriveConnected => _gdriveConnected;
  String get gdriveEmail => _gdriveEmail;

  AppStateProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final savedTheme = prefs.getString('ae_theme') ?? 'dark';
    _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

    // Language
    _currentLanguage = prefs.getString('ae_lang') ?? 'en';

    // Favorites
    final favStringList = prefs.getStringList('ae_tool_favs') ?? [];
    _favoriteToolIds = favStringList.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();

    // Profile
    _userName = prefs.getString('ae_name') ?? 'Guest User';
    _userEmail = prefs.getString('ae_email') ?? '';
    _userPhone = prefs.getString('ae_phone') ?? '';

    // Storage
    _storageType = prefs.getString('ae_storage') ?? 'local';
    _gdriveConnected = prefs.getBool('ae_gdrive') ?? false;
    _gdriveEmail = prefs.getString('ae_gdrive_email') ?? '';

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_theme', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_lang', langCode);
  }

  Future<void> toggleFavorite(int toolId) async {
    if (_favoriteToolIds.contains(toolId)) {
      _favoriteToolIds.remove(toolId);
    } else {
      _favoriteToolIds.add(toolId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ae_tool_favs', _favoriteToolIds.map((e) => e.toString()).toList());
  }

  bool isFavorite(int toolId) => _favoriteToolIds.contains(toolId);

  Future<void> updateProfile({required String name, required String email, required String phone}) async {
    _userName = name;
    _userEmail = email;
    _userPhone = phone;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_name', name);
    await prefs.setString('ae_email', email);
    await prefs.setString('ae_phone', phone);
  }

  Future<void> setStorageType(String type) async {
    _storageType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_storage', type);
  }

  Future<void> connectGDrive(String email) async {
    _gdriveConnected = true;
    _gdriveEmail = email;
    _storageType = 'gdrive';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ae_gdrive', true);
    await prefs.setString('ae_gdrive_email', email);
    await prefs.setString('ae_storage', 'gdrive');
  }

  Future<void> disconnectGDrive() async {
    _gdriveConnected = false;
    _gdriveEmail = '';
    _storageType = 'local';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ae_gdrive', false);
    await prefs.remove('ae_gdrive_email');
    await prefs.setString('ae_storage', 'local');
  }
}


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


class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('ae_notifs') ?? [];
    if (rawList.isEmpty) {
      // Add initial welcome notification
      _notifications = [
        AppNotification(
          id: 'welcome_1',
          type: 'info',
          title: 'Welcome to Architect Engine!',
          message: 'Start by creating your first architectural project or exploring 168 calculation tools.',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        )
      ];
    } else {
      _notifications = rawList.map((e) => AppNotification.fromMap(json.decode(e))).toList();
    }
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _notifications.map((e) => json.encode(e.toMap())).toList();
    await prefs.setStringList('ae_notifs', rawList);
  }

  Future<void> addNotification(String type, String title, String message) async {
    final newNotif = AppNotification(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      message: message,
      time: DateTime.now(),
      isRead: false,
    );
    _notifications.insert(0, newNotif);
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveNotifications();
  }
}


// ==========================================
// 5. DIALOGS & POPUPS
// ==========================================
import 'dart:math' as math;
class CalculatorDialog extends StatefulWidget {
  final ToolModel tool;

  const CalculatorDialog({super.key, required this.tool});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  final Map<String, TextEditingController> _controllers = {};
  String _selectedShape = 'rect';
  String _selectedUnitFrom = 'feet';
  String _selectedUnitTo = 'meter';
  String? _resultValue;
  String? _resultUnit;
  String? _resultExtra;

  @override
  void initState() {
    super.initState();
    _initControllersForTool();
  }

  void _initControllersForTool() {
    switch (widget.tool.id) {
      case 1: // Length
        _controllers['val'] = TextEditingController(text: '25');
        break;
      case 2: // Area
      case 3: // Perimeter
      case 4: // Volume
      case 5: // Surface Area
        _controllers['l'] = TextEditingController(text: '5.0');
        _controllers['w'] = TextEditingController(text: '4.0');
        _controllers['h'] = TextEditingController(text: '3.0');
        _controllers['r'] = TextEditingController(text: '2.5');
        break;
      case 6: // Scale
        _controllers['drawing'] = TextEditingController(text: '50');
        _controllers['scale'] = TextEditingController(text: '100');
        break;
      case 8: // Slope
        _controllers['rise'] = TextEditingController(text: '1');
        _controllers['run'] = TextEditingController(text: '20');
        break;
      case 17: // Built-up
        _controllers['carpet'] = TextEditingController(text: '80');
        _controllers['walls'] = TextEditingController(text: '12');
        break;
      case 19: // FSI
        _controllers['floor'] = TextEditingController(text: '300');
        _controllers['plot'] = TextEditingController(text: '200');
        break;
      case 22: // Staircase
        _controllers['height'] = TextEditingController(text: '3.0');
        _controllers['riser'] = TextEditingController(text: '0.15');
        _controllers['tread'] = TextEditingController(text: '0.28');
        break;
      case 28: // Excavation
      case 32: // Slab
        _controllers['l'] = TextEditingController(text: '10');
        _controllers['w'] = TextEditingController(text: '4');
        _controllers['d'] = TextEditingController(text: '1.5');
        _controllers['qty'] = TextEditingController(text: '1');
        break;
      case 36: // Brickwork
        _controllers['l'] = TextEditingController(text: '5.0');
        _controllers['h'] = TextEditingController(text: '3.0');
        _controllers['t'] = TextEditingController(text: '0.23');
        break;
      case 41: // Tile
        _controllers['area'] = TextEditingController(text: '20');
        _controllers['tileSize'] = TextEditingController(text: '0.6');
        _controllers['waste'] = TextEditingController(text: '5');
        break;
      case 43: // Paint
        _controllers['area'] = TextEditingController(text: '50');
        _controllers['coats'] = TextEditingController(text: '2');
        _controllers['coverage'] = TextEditingController(text: '10');
        break;
      case 51: // Cement
      case 54: // Concrete
        _controllers['vol'] = TextEditingController(text: '1.0');
        _controllers['cementRatio'] = TextEditingController(text: '1');
        _controllers['sandRatio'] = TextEditingController(text: '1.5');
        _controllers['aggRatio'] = TextEditingController(text: '3');
        break;
      case 58: // Steel weight
        _controllers['dia'] = TextEditingController(text: '12');
        _controllers['len'] = TextEditingController(text: '12');
        break;
      case 76: // BOQ Builder
      case 81: // Material Cost
        _controllers['qty'] = TextEditingController(text: '100');
        _controllers['rate'] = TextEditingController(text: '380');
        _controllers['tax'] = TextEditingController(text: '18');
        break;
      case 82: // Labour Cost
        _controllers['workers'] = TextEditingController(text: '10');
        _controllers['days'] = TextEditingController(text: '5');
        _controllers['wage'] = TextEditingController(text: '800');
        break;
      case 88: // Cost per sqft
        _controllers['cost'] = TextEditingController(text: '2400000');
        _controllers['area'] = TextEditingController(text: '1200');
        break;
      case 129: // Water demand
        _controllers['occupants'] = TextEditingController(text: '5');
        _controllers['lpcd'] = TextEditingController(text: '135');
        break;
      case 130: // Water Tank
        _controllers['l'] = TextEditingController(text: '2.0');
        _controllers['w'] = TextEditingController(text: '1.5');
        _controllers['h'] = TextEditingController(text: '1.5');
        break;
      default:
        _controllers['v1'] = TextEditingController(text: '10');
        _controllers['v2'] = TextEditingController(text: '20');
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _val(String key) => double.tryParse(_controllers[key]?.text ?? '0') ?? 0.0;

  void _calculate() {
    setState(() {
      switch (widget.tool.id) {
        case 1: // Unit Convert
          final v = _val('val');
          double inMeters = 0;
          if (_selectedUnitFrom == 'feet') inMeters = v * 0.3048;
          else if (_selectedUnitFrom == 'inch') inMeters = v * 0.0254;
          else inMeters = v;

          double res = inMeters;
          if (_selectedUnitTo == 'feet') res = inMeters / 0.3048;
          else if (_selectedUnitTo == 'inch') res = inMeters / 0.0254;

          _resultValue = res.toStringAsFixed(3);
          _resultUnit = _selectedUnitTo.toUpperCase();
          _resultExtra = '$v $_selectedUnitFrom = ${_resultValue} $_selectedUnitTo';
          break;

        case 2: // Area
          if (_selectedShape == 'rect') {
            final a = _val('l') * _val('w');
            _resultValue = a.toStringAsFixed(2);
            _resultUnit = 'sq.m (m²)';
            _resultExtra = 'Rectangle: ${_val('l')}m × ${_val('w')}m';
          } else if (_selectedShape == 'tri') {
            final a = 0.5 * _val('l') * _val('h');
            _resultValue = a.toStringAsFixed(2);
            _resultUnit = 'sq.m (m²)';
            _resultExtra = 'Triangle: 0.5 × Base × Height';
          } else {
            final a = math.pi * math.pow(_val('r'), 2);
            _resultValue = a.toStringAsFixed(2);
            _resultUnit = 'sq.m (m²)';
            _resultExtra = 'Circle: π × r² (radius: ${_val('r')}m)';
          }
          break;

        case 6: // Drawing Scale
          final d = _val('drawing');
          final s = _val('scale');
          final realMeters = (d * s) / 1000.0;
          _resultValue = '${realMeters.toStringAsFixed(2)} m';
          _resultUnit = 'Real World Length';
          _resultExtra = 'Scale 1:$s for ${d}mm on drawing';
          break;

        case 8: // Slope
          final rise = _val('rise');
          final run = _val('run');
          if (run > 0) {
            final pct = (rise / run) * 100;
            final deg = math.atan(rise / run) * (180 / math.pi);
            _resultValue = '${pct.toStringAsFixed(2)} %';
            _resultUnit = 'Gradient / Slope';
            _resultExtra = 'Ratio 1:${(run / rise).toStringAsFixed(1)} • Angle: ${deg.toStringAsFixed(1)}°';
          }
          break;

        case 17: // Built-up Area
          final c = _val('carpet');
          final w = _val('walls');
          _resultValue = (c + w).toStringAsFixed(2);
          _resultUnit = 'sq.m Built-up Area';
          _resultExtra = 'Carpet (${c}m²) + Walls & Balconies (${w}m²)';
          break;

        case 19: // FSI / FAR
          final f = _val('floor');
          final p = _val('plot');
          if (p > 0) {
            _resultValue = (f / p).toStringAsFixed(2);
            _resultUnit = 'FSI / FAR Index';
            _resultExtra = 'Total Covered Floor Area / Plot Area';
          }
          break;

        case 22: // Staircase
          final h = _val('height');
          final r = _val('riser');
          final t = _val('tread');
          if (r > 0) {
            final risers = (h / r).ceil();
            final treads = risers - 1;
            final totalRun = treads * t;
            _resultValue = '$risers Risers';
            _resultUnit = 'Staircase Dimensions';
            _resultExtra = '$treads Treads • Total Run: ${totalRun.toStringAsFixed(2)} m';
          }
          break;

        case 28: // Excavation
        case 32: // Slab Concrete
          final vol = _val('l') * _val('w') * _val('d') * (_val('qty') > 0 ? _val('qty') : 1.0);
          _resultValue = '${vol.toStringAsFixed(2)} m³';
          _resultUnit = 'Total Volume';
          _resultExtra = 'Approx ${(vol * 35.3147).toStringAsFixed(1)} cubic feet (cft)';
          break;

        case 36: // Brickwork
          final vol = _val('l') * _val('h') * _val('t');
          final bricks = (vol * 500).ceil();
          _resultValue = '$bricks Bricks';
          _resultUnit = 'Masonry Material';
          _resultExtra = 'Wall volume: ${vol.toStringAsFixed(2)} m³ (at 500 bricks/m³)';
          break;

        case 41: // Tile Calculator
          final a = _val('area');
          final s = _val('tileSize');
          final w = _val('waste');
          if (s > 0) {
            final tileArea = s * s;
            final count = (a / tileArea) * (1 + w / 100.0);
            _resultValue = '${count.ceil()} Tiles';
            _resultUnit = 'Total Tiles Required';
            _resultExtra = 'Includes $w% cutting & breakage wastage';
          }
          break;

        case 43: // Painting
          final a = _val('area');
          final coats = _val('coats');
          final cov = _val('coverage');
          if (cov > 0) {
            final litres = (a * coats) / cov;
            _resultValue = '${litres.toStringAsFixed(1)} Litres';
            _resultUnit = 'Paint Required';
            _resultExtra = 'For $coats coats over ${a}m² surface';
          }
          break;

        case 51: // Cement Bags
        case 54: // Concrete Material
          final v = _val('vol');
          final c = _val('cementRatio');
          final s = _val('sandRatio');
          final a = _val('aggRatio');
          final total = c + s + a;
          final dryVol = v * 1.54; // Standard dry volume factor
          if (total > 0) {
            final cementM3 = (c / total) * dryVol;
            final bags = (cementM3 * 1440.0 / 50.0).ceil(); // 1440 kg/m3 density, 50kg bag
            final sandM3 = (s / total) * dryVol;
            final aggM3 = (a / total) * dryVol;
            _resultValue = '$bags Bags';
            _resultUnit = 'Cement (50 kg bags)';
            _resultExtra = 'Sand: ${sandM3.toStringAsFixed(2)} m³ • Aggregates: ${aggM3.toStringAsFixed(2)} m³';
          }
          break;

        case 58: // Steel Weight
          final dia = _val('dia');
          final len = _val('len');
          final wtPerM = (dia * dia) / 162.0;
          final totalWt = wtPerM * len;
          _resultValue = '${totalWt.toStringAsFixed(2)} kg';
          _resultUnit = 'Reinforcement Steel Weight';
          _resultExtra = 'D²/162 formula: ${wtPerM.toStringAsFixed(3)} kg/meter';
          break;

        case 76: // BOQ Builder
        case 81: // Material Cost
          final q = _val('qty');
          final r = _val('rate');
          final t = _val('tax');
          final base = q * r;
          final total = base * (1 + t / 100.0);
          _resultValue = '₹ ${total.toStringAsFixed(0)}';
          _resultUnit = 'Total Estimated Cost';
          _resultExtra = 'Base: ₹${base.toStringAsFixed(0)} + $t% GST/Overheads';
          break;

        case 82: // Labour Cost
          final w = _val('workers');
          final d = _val('days');
          final wage = _val('wage');
          final total = w * d * wage;
          _resultValue = '₹ ${total.toStringAsFixed(0)}';
          _resultUnit = 'Labour Expenditure';
          _resultExtra = '$w workers for $d days at ₹$wage/day';
          break;

        case 88: // Cost per sqft
          final cost = _val('cost');
          final area = _val('area');
          if (area > 0) {
            final rate = cost / area;
            _resultValue = '₹ ${rate.toStringAsFixed(1)} / sq.ft';
            _resultUnit = 'Unit Rate';
            _resultExtra = 'Total ₹${cost.toStringAsFixed(0)} for ${area.toStringAsFixed(0)} sq.ft';
          }
          break;

        case 129: // Water Demand
          final occ = _val('occupants');
          final lpcd = _val('lpcd');
          final totalL = occ * lpcd;
          _resultValue = '${totalL.toStringAsFixed(0)} Litres / day';
          _resultUnit = 'Daily Water Consumption';
          _resultExtra = '$occ persons at $lpcd Litres per capita per day (NBC)';
          break;

        case 130: // Water Tank Volume
          final l = _val('l');
          final w = _val('w');
          final h = _val('h');
          final vol = l * w * h;
          final litres = vol * 1000.0;
          _resultValue = '${litres.toStringAsFixed(0)} Litres';
          _resultUnit = 'Tank Capacity';
          _resultExtra = 'Physical Dimensions: ${vol.toStringAsFixed(2)} m³ volume';
          break;

        default:
          final v1 = _val('v1');
          final v2 = _val('v2');
          _resultValue = (v1 * v2).toStringAsFixed(2);
          _resultUnit = 'Output Result';
          _resultExtra = 'Calculation based on inputs $v1 and $v2';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isFav = appState.isFavorite(widget.tool.id);

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.darkIconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.tool.icon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tool.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          widget.tool.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => appState.toggleFavorite(widget.tool.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Inputs based on Tool ID
              _buildInputs(),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  foregroundColor: const Color(0xFF0A1128),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'CALCULATE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                ),
              ),

              // Result Card
              if (_resultValue != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkPrimary, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CALCULATION RESULT',
                        style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _resultValue!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_resultUnit != null)
                        Text(
                          _resultUnit!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      if (_resultExtra != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _resultExtra!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputs() {
    switch (widget.tool.id) {
      case 1:
        return Column(
          children: [
            _buildField('val', 'Distance / Length Value'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnitFrom,
                    decoration: const InputDecoration(labelText: 'From Unit'),
                    items: const [
                      DropdownMenuItem(value: 'feet', child: Text('Feet')),
                      DropdownMenuItem(value: 'meter', child: Text('Meter')),
                      DropdownMenuItem(value: 'inch', child: Text('Inch')),
                    ],
                    onChanged: (v) => setState(() => _selectedUnitFrom = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnitTo,
                    decoration: const InputDecoration(labelText: 'To Unit'),
                    items: const [
                      DropdownMenuItem(value: 'meter', child: Text('Meter')),
                      DropdownMenuItem(value: 'feet', child: Text('Feet')),
                      DropdownMenuItem(value: 'inch', child: Text('Inch')),
                    ],
                    onChanged: (v) => setState(() => _selectedUnitTo = v!),
                  ),
                ),
              ],
            ),
          ],
        );

      case 2:
      case 3:
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedShape,
              decoration: const InputDecoration(labelText: 'Geometric Shape'),
              items: const [
                DropdownMenuItem(value: 'rect', child: Text('Rectangle / Square')),
                DropdownMenuItem(value: 'tri', child: Text('Triangle')),
                DropdownMenuItem(value: 'circ', child: Text('Circle')),
              ],
              onChanged: (v) => setState(() => _selectedShape = v!),
            ),
            const SizedBox(height: 10),
            if (_selectedShape == 'rect') ...[
              Row(
                children: [
                  Expanded(child: _buildField('l', 'Length (m)')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField('w', 'Width (m)')),
                ],
              ),
            ] else if (_selectedShape == 'tri') ...[
              Row(
                children: [
                  Expanded(child: _buildField('l', 'Base (m)')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField('h', 'Height (m)')),
                ],
              ),
            ] else ...[
              _buildField('r', 'Radius (m)'),
            ],
          ],
        );

      case 6:
        return Row(
          children: [
            Expanded(child: _buildField('drawing', 'Drawing Dimension (mm)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('scale', 'Scale 1:X (e.g. 100)')),
          ],
        );

      case 8:
        return Row(
          children: [
            Expanded(child: _buildField('rise', 'Vertical Rise (m)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('run', 'Horizontal Run (m)')),
          ],
        );

      case 22:
        return Column(
          children: [
            _buildField('height', 'Total Floor Height (m)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('riser', 'Riser Height (e.g. 0.15m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('tread', 'Tread Depth (e.g. 0.28m)')),
              ],
            ),
          ],
        );

      case 28:
      case 32:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildField('l', 'Length (m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('w', 'Width (m)')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('d', 'Depth / Thickness (m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('qty', 'Quantity (Units)')),
              ],
            ),
          ],
        );

      case 36:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildField('l', 'Wall Length (m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('h', 'Wall Height (m)')),
              ],
            ),
            const SizedBox(height: 10),
            _buildField('t', 'Wall Thickness (m, e.g. 0.23m / 9")'),
          ],
        );

      case 51:
      case 54:
        return Column(
          children: [
            _buildField('vol', 'Wet Concrete Volume (m³)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('cementRatio', 'Cement')),
                const SizedBox(width: 8),
                Expanded(child: _buildField('sandRatio', 'Sand')),
                const SizedBox(width: 8),
                Expanded(child: _buildField('aggRatio', 'Aggregate')),
              ],
            ),
          ],
        );

      case 58:
        return Row(
          children: [
            Expanded(child: _buildField('dia', 'Bar Diameter (mm)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('len', 'Total Bar Length (m)')),
          ],
        );

      case 76:
      case 81:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildField('qty', 'Quantity')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('rate', 'Rate per Unit (₹)')),
              ],
            ),
            const SizedBox(height: 10),
            _buildField('tax', 'GST & Overheads (%)'),
          ],
        );

      case 88:
        return Row(
          children: [
            Expanded(child: _buildField('cost', 'Total Cost (₹)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('area', 'Built-up Area (sq.ft)')),
          ],
        );

      case 130:
        return Row(
          children: [
            Expanded(child: _buildField('l', 'Length (m)')),
            const SizedBox(width: 8),
            Expanded(child: _buildField('w', 'Width (m)')),
            const SizedBox(width: 8),
            Expanded(child: _buildField('h', 'Height (m)')),
          ],
        );

      default:
        return Row(
          children: [
            Expanded(child: _buildField('v1', 'Primary Dimension / Qty')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('v2', 'Secondary Factor / Rate')),
          ],
        );
    }
  }

  Widget _buildField(String key, String label) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}


class ProjectFormDialog extends StatefulWidget {
  final ProjectModel? existingProject;

  const ProjectFormDialog({super.key, this.existingProject});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late String _bhk;
  late String _floors;
  late String _facing;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _nameController = TextEditingController(text: p?.name ?? '');
    _lengthController = TextEditingController(text: p != null ? p.length.toString() : '40');
    _widthController = TextEditingController(text: p != null ? p.width.toString() : '30');
    _bhk = p?.bhk ?? '2 BHK';
    _floors = p?.floors ?? 'Ground floor';
    _facing = p?.facing ?? 'North';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final length = double.parse(_lengthController.text);
      final width = double.parse(_widthController.text);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

      if (widget.existingProject != null) {
        projectProvider.updateProject(
          id: widget.existingProject!.id,
          name: name,
          length: length,
          width: width,
          bhk: _bhk,
          floors: _floors,
          facing: _facing,
        );
        notifProvider.addNotification('success', 'Project Updated', '$name has been updated.');
      } else {
        projectProvider.addProject(
          name: name,
          length: length,
          width: width,
          bhk: _bhk,
          floors: _floors,
          facing: _facing,
        );
        notifProvider.addNotification('success', 'New Project Created', '$name ($bhk, ${length * width} sqft) was created.');
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingProject != null ? 'Project updated!' : 'Project created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProject != null;

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text(
                      isEditing ? 'Edit Project' : 'Create New Project',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Project Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    hintText: 'e.g. Sharma Villa, My 2BHK Home',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a project name' : null,
                ),
                const SizedBox(height: 14),

                // Plot Dimensions
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Plot Length (ft) *',
                          hintText: '40',
                        ),
                        validator: (v) {
                          final num = double.tryParse(v ?? '');
                          if (num == null || num <= 0) return 'Valid length';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Plot Width (ft) *',
                          hintText: '30',
                        ),
                        validator: (v) {
                          final num = double.tryParse(v ?? '');
                          if (num == null || num <= 0) return 'Valid width';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // BHK and Floors
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _bhk,
                        decoration: const InputDecoration(labelText: 'BHK Type'),
                        items: const [
                          DropdownMenuItem(value: '1 BHK', child: Text('1 BHK')),
                          DropdownMenuItem(value: '2 BHK', child: Text('2 BHK')),
                          DropdownMenuItem(value: '3 BHK', child: Text('3 BHK')),
                          DropdownMenuItem(value: '4 BHK', child: Text('4 BHK')),
                          DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                        ],
                        onChanged: (v) => setState(() => _bhk = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _floors,
                        decoration: const InputDecoration(labelText: 'Floors'),
                        items: const [
                          DropdownMenuItem(value: 'Ground floor', child: Text('Ground floor')),
                          DropdownMenuItem(value: 'G+1', child: Text('G+1')),
                          DropdownMenuItem(value: 'G+2', child: Text('G+2')),
                          DropdownMenuItem(value: 'G+3', child: Text('G+3')),
                          DropdownMenuItem(value: 'G+4 or more', child: Text('G+4 or more')),
                        ],
                        onChanged: (v) => setState(() => _floors = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Facing Direction
                DropdownButtonFormField<String>(
                  value: _facing,
                  decoration: const InputDecoration(labelText: 'Plot Facing (Vastu)'),
                  items: const [
                    DropdownMenuItem(value: 'North', child: Text('North')),
                    DropdownMenuItem(value: 'East', child: Text('East')),
                    DropdownMenuItem(value: 'South', child: Text('South')),
                    DropdownMenuItem(value: 'West', child: Text('West')),
                    DropdownMenuItem(value: 'North-East', child: Text('North-East')),
                    DropdownMenuItem(value: 'North-West', child: Text('North-West')),
                    DropdownMenuItem(value: 'South-East', child: Text('South-East')),
                    DropdownMenuItem(value: 'South-West', child: Text('South-West')),
                    DropdownMenuItem(value: 'Not decided', child: Text('Not decided')),
                  ],
                  onChanged: (v) => setState(() => _facing = v!),
                ),
                const SizedBox(height: 24),

                // Actions
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimary,
                    foregroundColor: const Color(0xFF0A1128),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: Text(
                    isEditing ? 'UPDATE PROJECT' : 'SAVE PROJECT',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ==========================================
// 6. APPLICATION SCREENS
// ==========================================
class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ARCHITECTURAL WORKSPACE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.darkPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Turn your ideas into\nprofessional drawings.',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start your next architectural project today with automated spatial planning and Vastu rules.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimary,
                    foregroundColor: const Color(0xFF0A1128),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ProjectFormDialog(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Create New Project',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Header: My Projects
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text(
                'My Projects',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigateTab(1),
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Projects List or Empty State
          if (!projectProvider.hasProjects)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('📁', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  const Text(
                    'No Projects Yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your first architectural project to get started.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkPrimary,
                      side: const BorderSide(color: AppColors.darkPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ProjectFormDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Project'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projectProvider.projects.take(3).length,
              itemBuilder: (context, index) {
                final project = projectProvider.projects[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.darkPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text('📐', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '${project.bhk} • ${project.floors} • ${project.facing} Facing',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (_) => ProjectFormDialog(existingProject: project),
                                );
                              } else if (val == 'dup') {
                                projectProvider.duplicateProject(project.id);
                              } else if (val == 'del') {
                                projectProvider.deleteProject(project.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'dup', child: Text('Duplicate')),
                              const PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkIconBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Plot: ${project.length} × ${project.width} ft',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkIconBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${project.areaSqFt.toStringAsFixed(0)} sq.ft',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Design Studio Modules Shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text(
                'Design Modules',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigateTab(2),
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _buildShortcutCard(context, icon: '📐', title: 'Floor Plan', sub: 'Detailed layouts', tabIndex: 2),
              _buildShortcutCard(context, icon: '🏞️', title: 'Site Plan', sub: 'Plot & orientation', tabIndex: 2),
              _buildShortcutCard(context, icon: '🏠', title: 'Elevation', sub: 'Exterior views', tabIndex: 2),
              _buildShortcutCard(context, icon: '📦', title: '3D View', sub: 'Spatial model', tabIndex: 2),
            ],
          ),

          const SizedBox(height: 24),

          // Tools & Utilities Shortcut
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text(
                'Engineering & Tools',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigateTab(3),
                child: const Text('168 Tools', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildCompactToolCategory(context, icon: '📏', title: 'Measurement', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '👷', title: 'Construction', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '🧱', title: 'Materials & Steel', tabIndex: 3),
              _buildCompactToolCategory(context, icon: '💰', title: 'Cost & BOQ', tabIndex: 3),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShortcutCard(BuildContext context, {required String icon, required String title, required String sub, required int tabIndex}) {
    return InkWell(
      onTap: () => onNavigateTab(tabIndex),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToolCategory(BuildContext context, {required String icon, required String title, required int tabIndex}) {
    return InkWell(
      onTap: () => onNavigateTab(tabIndex),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DesignScreen extends StatelessWidget {
  const DesignScreen({super.key});

  void _showModuleDetails(BuildContext context, DesignModule module) {
    final details = DesignData.moduleDetails[module.id] ?? {
      'name': 'Design Module',
      'desc': 'Architectural engineering module',
      'full': 'Building coordinated drawings and layouts.',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.darkIconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(module.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(details['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(details['desc']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(
                  details['full']!,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🚧', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Interactive Editor In Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Full vector drawing and CAD editing tools are in active development.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).cardColor, Theme.of(context).scaffoldBackgroundColor],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkIconBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('DESIGN STUDIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkPrimary)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Turn concepts into coordinated designs.', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Start a design, review floor plans, or inspect building module specifications.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text('Design Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${DesignData.modules.length} modules', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: DesignData.modules.length,
              itemBuilder: (context, index) {
                final module = DesignData.modules[index];
                final details = DesignData.moduleDetails[module.id] ?? {'name': 'Module', 'desc': ''};

                return InkWell(
                  onTap: () => _showModuleDetails(context, module),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.darkIconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(module.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: module.status == 'progress'
                                    ? AppColors.statusProgressBg
                                    : AppColors.statusPlannedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                module.status == 'progress' ? 'In Progress' : 'Planned',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: module.status == 'progress'
                                      ? AppColors.statusProgressText
                                      : AppColors.statusPlannedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(details['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(details['desc']!, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class ProfessionalScreen extends StatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  String _searchQuery = '';

  void _showModuleDetails(BuildContext context, ProfessionalModule m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.darkIconBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(m.icon, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.key.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(m.status == 'progress' ? 'In Development' : 'Planned Specification', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Overview
                  const Text('📌 Architectural Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.fullDescription, style: const TextStyle(fontSize: 12, height: 1.5)),
                  ),
                  const SizedBox(height: 16),

                  // Uses
                  const Text('🎯 Specific Professional Capabilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkPrimary)),
                  const SizedBox(height: 6),
                  ...m.uses.map((u) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✓ ', style: TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(u, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),

                  // Screen Design
                  const Text('🖥️ Interface & Canvas Specs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.screenDesign, style: const TextStyle(fontSize: 12, height: 1.5)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ProfessionalData.modules.where((m) {
      return m.fullDescription.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).cardColor, Theme.of(context).scaffoldBackgroundColor],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('PROFESSIONAL CAD STUDIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkPrimary)),
                  SizedBox(height: 10),
                  Text('Precision • Control • Documentation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Advanced CAD vector drafting, drafting standards, layers, and BIM export workflows.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search professional CAD modules...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text('Professional Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${filtered.length} modules', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final m = filtered[index];
                return InkWell(
                  onTap: () => _showModuleDetails(context, m),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.darkIconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(m.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: m.status == 'progress' ? AppColors.statusProgressBg : AppColors.statusPlannedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                m.status == 'progress' ? 'In Progress' : 'Planned',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: m.status == 'progress' ? AppColors.statusProgressText : AppColors.statusPlannedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(m.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(m.fullDescription, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class ToolsScreen extends StatefulWidget {
  final String? initialCategory;

  const ToolsScreen({super.key, this.initialCategory});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _selectedCat = 'all';
  String _searchQuery = '';
  int _renderLimit = 30;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCat = widget.initialCategory!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    // Filter tools
    List<ToolModel> list = ToolsData.allTools;
    if (_selectedCat == 'fav') {
      list = list.where((t) => appState.isFavorite(t.id)).toList();
    } else if (_selectedCat != 'all') {
      list = list.where((t) => t.category == _selectedCat).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) => t.name.toLowerCase().contains(q) || t.description.toLowerCase().contains(q)).toList();
    }

    final visibleTools = list.take(_renderLimit).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '168 Professional Tools',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Civil engineering, BOQ takeoffs, structural, and architectural calculators',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  // Search Box
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search 168 tools (e.g. concrete, steel, tile, boq)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ToolsData.categories.length,
                      itemBuilder: (context, index) {
                        final cat = ToolsData.categories[index];
                        final isSelected = cat.id == _selectedCat;
                        final countText = (cat.id == 'fav' && appState.favoriteToolIds.isNotEmpty)
                            ? ' (${appState.favoriteToolIds.length})'
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${cat.icon} ${cat.translationKey}$countText'),
                            selected: isSelected,
                            selectedColor: AppColors.darkPrimary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF0A1128) : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            backgroundColor: Theme.of(context).cardColor,
                            onSelected: (_) {
                              setState(() {
                                _selectedCat = cat.id;
                                _renderLimit = 30;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tools Grid
          if (visibleTools.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('🔍 No tools found matching criteria', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = visibleTools[index];
                    final isFav = appState.isFavorite(tool.id);

                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => CalculatorDialog(tool: tool),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.between,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkIconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(tool.icon, style: const TextStyle(fontSize: 19)),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    size: 18,
                                    color: isFav ? Colors.amber : Colors.grey,
                                  ),
                                  onPressed: () => appState.toggleFavorite(tool.id),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              tool.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tool.description,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: visibleTools.length,
                ),
              ),
            ),

          // Load More button
          if (list.length > _renderLimit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.darkPrimary),
                    foregroundColor: AppColors.darkPrimary,
                  ),
                  onPressed: () => setState(() => _renderLimit += 30),
                  child: Text('LOAD MORE (${_renderLimit}/${list.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class VastuScreen extends StatelessWidget {
  const VastuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vastu Shastra Guide')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: VastuData.items.length,
        itemBuilder: (context, index) {
          final item = VastuData.items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: item.guidelines.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                          Expanded(child: Text(g, style: const TextStyle(fontSize: 13, height: 1.4))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final TextEditingController _val = TextEditingController(text: '1000');
  double _factor = 0.0929;
  String _unitName = 'Square Meter';

  @override
  void dispose() {
    _val.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputVal = double.tryParse(_val.text) ?? 0.0;
    final result = inputVal * _factor;

    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _val,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'From Area (Square Feet / sq.ft)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              value: _factor,
              decoration: const InputDecoration(labelText: 'Convert To'),
              items: const [
                DropdownMenuItem(value: 0.092903, child: Text('Square Meter (sq.m)')),
                DropdownMenuItem(value: 0.111111, child: Text('Square Yard (Gaj)')),
                DropdownMenuItem(value: 0.0000229568, child: Text('Acre')),
                DropdownMenuItem(value: 0.00091827, child: Text('Guntha')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _factor = v;
                    if (v == 0.092903) _unitName = 'sq.m';
                    else if (v == 0.111111) _unitName = 'Gaj (sq.yd)';
                    else if (v == 0.0000229568) _unitName = 'Acre';
                    else _unitName = 'Guntha';
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('CONVERTED VALUE', style: TextStyle(color: Color(0xFF0A1128), fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(
                    '${result.toStringAsFixed(4)} $_unitName',
                    style: const TextStyle(color: Color(0xFF0A1128), fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class TutorialsScreen extends StatelessWidget {
  const TutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorials & Workflows')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: TutorialsData.items.length,
        itemBuilder: (context, index) {
          final tut = TutorialsData.items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            child: ExpansionTile(
              leading: Text(tut.icon, style: const TextStyle(fontSize: 24)),
              title: Text(tut.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(tut.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tut.intro, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      ...tut.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.key + 1}. ', style: const TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12, height: 1.4))),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.darkPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tut.tip, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: FAQData.items.length,
        itemBuilder: (context, index) {
          final faq = FAQData.items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            child: ExpansionTile(
              title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq.answer,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ==========================================
// 7. MAIN SCAFFOLD & ENTRY POINT
// ==========================================

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    final List<Widget> screens = [
      HomeScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const ProfessionalScreen(),
      const DesignScreen(),
      const ToolsScreen(),
    ];

    final titles = [
      'ARCHITECT ENGINE',
      'PROFESSIONAL STUDIO',
      'DESIGN STUDIO',
      'TOOLS & UTILITIES',
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Theme.of(context).cardColor,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('👤', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Design • Plan • Build', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Projects (CAD)'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.architecture),
                title: const Text('Design Studio (11 Modules)'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.handyman_outlined),
                title: const Text('168 Tools & Calculators'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.compass_calibration_outlined),
                title: const Text('Vastu Shastra Guide'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VastuScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Unit Converter'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitConverterScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Tutorials & Guides'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & FAQ'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen()));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Toggle Theme'),
                trailing: Text(appState.isDarkMode ? '🌙 Dark' : '☀️ Light'),
                onTap: () => appState.toggleTheme(),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            const Text('📐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            icon: Text(appState.isDarkMode ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
            onPressed: () => appState.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: AppColors.darkPrimary.withOpacity(0.2),
        onDestinationSelected: (idx) {
          if (idx == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => _currentIndex = idx);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.architecture), label: 'Design'),
          NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const ArchitectEngineApp(),
    ),
  );
}

class ArchitectEngineApp extends StatelessWidget {
  const ArchitectEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp(
      title: 'Architect Engine',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: appState.themeMode,
      home: const MainScaffold(),
    );
  }
}

