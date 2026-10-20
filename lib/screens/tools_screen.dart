import 'dart:math' as math;
import 'package:flutter/material.dart';

// --- Tool Data Models ---
class ToolItem {
  final int id;
  final String category;
  final String icon;
  final String name;
  final String description;
  final bool isWorking;

  const ToolItem({
    required this.id,
    required this.category,
    required this.icon,
    required this.name,
    required this.description,
    this.isWorking = true,
  });
}

class ToolCategoryItem {
  final String id;
  final String name;
  final String icon;

  const ToolCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
  });
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
  final Set<int> _favorites = {1, 2, 19, 36, 54, 58};

  static const Color darkBg = Color(0xFF0A1128);
  static const Color darkCard = Color(0xFF131C35);
  static const Color goldAccent = Color(0xFFE5B05C);
  static const Color darkBorder = Color(0x33E5B05C);
  static const Color darkIconBg = Color(0xFF1E293B);

  final List<ToolCategoryItem> _categories = const [
    ToolCategoryItem(id: 'all', name: 'All Tools', icon: '🧰'),
    ToolCategoryItem(id: 'fav', name: 'Favorites', icon: '⭐'),
    ToolCategoryItem(id: 'measure', name: 'Measurement', icon: '📏'),
    ToolCategoryItem(id: 'arch', name: 'Architecture', icon: '📐'),
    ToolCategoryItem(id: 'const', name: 'Construction', icon: '👷'),
    ToolCategoryItem(id: 'mat', name: 'Materials & Steel', icon: '🧱'),
    ToolCategoryItem(id: 'boq', name: 'BOQ & Takeoff', icon: '📋'),
    ToolCategoryItem(id: 'cost', name: 'Cost & Budget', icon: '🪙'),
    ToolCategoryItem(id: 'slope', name: 'Slopes & Levels', icon: '📉'),
    ToolCategoryItem(id: 'struct', name: 'Structural', icon: '🏗️'),
    ToolCategoryItem(id: 'elec', name: 'Electrical', icon: '⚡'),
    ToolCategoryItem(id: 'plumb', name: 'Plumbing', icon: '🚿'),
    ToolCategoryItem(id: 'math', name: 'Math Utilities', icon: '🧮'),
    ToolCategoryItem(id: 'site', name: 'Site Logs', icon: '📑'),
  ];

  final List<ToolItem> _allTools = const [
    ToolItem(id: 1, category: 'measure', icon: '📏', name: 'Length & Unit Converter', description: 'Convert Feet, Meters, Inches, Yards'),
    ToolItem(id: 2, category: 'measure', icon: '📐', name: 'Area Calculator', description: 'Rectangle, Triangle, Circle area'),
    ToolItem(id: 3, category: 'measure', icon: '🔲', name: 'Perimeter Calculator', description: 'Boundary and perimeter of shapes'),
    ToolItem(id: 4, category: 'measure', icon: '📦', name: 'Volume Calculator', description: 'Cubic volume of 3D structures'),
    ToolItem(id: 5, category: 'measure', icon: '🎯', name: 'Surface Area Calc', description: 'Total surface area for finishes'),
    ToolItem(id: 6, category: 'measure', icon: '📐', name: 'Drawing Scale', description: 'Scale factor conversion (1:50, 1:100)'),
    ToolItem(id: 7, category: 'measure', icon: '📊', name: 'Dimension Adder', description: 'Sum series of blueprint dimensions'),
    ToolItem(id: 8, category: 'measure', icon: '📉', name: 'Slope & Gradient', description: 'Rise/run ratio, % grade, angles'),
    ToolItem(id: 9, category: 'measure', icon: '📏', name: 'Level Difference', description: 'Survey and contour elevations'),
    ToolItem(id: 10, category: 'measure', icon: '📐', name: 'Angle & Diagonal Calc', description: 'Pythagorean right angle validation'),
    
    // Architecture
    ToolItem(id: 14, category: 'arch', icon: '🚪', name: 'Room Area Analyzer', description: 'Length × Width room space sizing'),
    ToolItem(id: 15, category: 'arch', icon: '🏠', name: 'Total Floor Area', description: 'Sum total covered floor plates'),
    ToolItem(id: 16, category: 'arch', icon: '🛋️', name: 'Carpet Area (RERA)', description: 'Actual usable room interior floor'),
    ToolItem(id: 17, category: 'arch', icon: '🏢', name: 'Built-up Area', description: 'Carpet area + wall thickness + ducts'),
    ToolItem(id: 18, category: 'arch', icon: '📐', name: 'Plot Coverage %', description: 'Ground floor footprint vs total plot'),
    ToolItem(id: 19, category: 'arch', icon: '📊', name: 'FSI / FAR Index', description: 'Floor Space Index & bylaws capacity'),
    ToolItem(id: 20, category: 'arch', icon: '🧱', name: 'Wall Area & Deductions', description: 'Gross wall area minus door openings'),
    ToolItem(id: 21, category: 'arch', icon: '🚪', name: 'Door & Window Schedule', description: 'Openings count, lintel & sill specs'),
    ToolItem(id: 22, category: 'arch', icon: '🪜', name: 'Staircase Dimensions', description: 'Riser, tread count & headroom flight'),
    ToolItem(id: 23, category: 'arch', icon: '📐', name: 'Ramp Slope Checker', description: 'Handicap & vehicle ramp gradient'),
    ToolItem(id: 24, category: 'arch', icon: '🚗', name: 'Parking Bay Sizing', description: 'Car parking area & driveway turning'),
    
    // Construction
    ToolItem(id: 28, category: 'const', icon: '⛏️', name: 'Excavation Volume', description: 'Pit length × width × foundation depth'),
    ToolItem(id: 29, category: 'const', icon: '🚜', name: 'Earthwork Cut & Fill', description: 'Site leveling soil displacement'),
    ToolItem(id: 30, category: 'const', icon: '🪨', name: 'PCC Foundation Bed', description: 'Plain cement concrete levelling layer'),
    ToolItem(id: 31, category: 'const', icon: '🏗️', name: 'RCC Volume Takeoff', description: 'Reinforced concrete total casting'),
    ToolItem(id: 32, category: 'const', icon: '🧱', name: 'Slab Concrete Casting', description: 'Roof slab thickness & cubic meters'),
    ToolItem(id: 33, category: 'const', icon: '📏', name: 'Beam Concrete Volume', description: 'Span × depth × width concrete qty'),
    ToolItem(id: 34, category: 'const', icon: '🏛️', name: 'Column Concrete Volume', description: 'Vertical column casting calculations'),
    ToolItem(id: 35, category: 'const', icon: '⚓', name: 'Footing Concrete Volume', description: 'Trapezoidal & pad footing takeoff'),
    ToolItem(id: 36, category: 'const', icon: '🧱', name: 'Brickwork Calculator', description: 'Number of bricks & cement mortar'),
    ToolItem(id: 37, category: 'const', icon: '🧱', name: 'AAC Blockwork Calc', description: 'AAC blocks & thin-bed adhesive'),
    ToolItem(id: 38, category: 'const', icon: '🥣', name: 'Mortar Batch Volume', description: '1:4 / 1:6 cement-sand mortar mixing'),
    ToolItem(id: 39, category: 'const', icon: '🖌️', name: 'Plastering Volume', description: '12mm internal & 20mm external plaster'),
    ToolItem(id: 40, category: 'const', icon: '🔲', name: 'Flooring Surface Area', description: 'Room floor finishing takeoff'),
    ToolItem(id: 41, category: 'const', icon: '✨', name: 'Tile Calculator', description: 'Number of floor/wall tiles + wastage'),
    ToolItem(id: 42, category: 'const', icon: '📏', name: 'Skirting Length', description: 'Perimeter skirting minus door widths'),
    ToolItem(id: 43, category: 'const', icon: '🎨', name: 'Paint Coverage & Litres', description: 'Wall surface paint coats & litres'),
    ToolItem(id: 44, category: 'const', icon: '🎨', name: 'Primer & Wall Putty', description: 'Surface preparation bags & litres'),
    ToolItem(id: 45, category: 'const', icon: '💧', name: 'Waterproofing Surface', description: 'Terrace & bathroom membrane coats'),
    ToolItem(id: 48, category: 'const', icon: '🪵', name: 'Shuttering / Formwork', description: 'Plywood & steel shuttering area'),
    ToolItem(id: 49, category: 'const', icon: '🧮', name: 'Concrete Wastage Factor', description: 'Standard 5% - 8% transit allowance'),
    
    // Materials
    ToolItem(id: 51, category: 'mat', icon: '🏗️', name: 'Cement Bag Calculator', description: '50kg cement bags for given wet volume'),
    ToolItem(id: 52, category: 'mat', icon: '⏳', name: 'Sand / River Sand (cft)', description: 'Sand volume in cubic meters & cu.ft'),
    ToolItem(id: 53, category: 'mat', icon: '🪨', name: 'Coarse Aggregate (Grit)', description: '10mm/20mm gravel aggregate volume'),
    ToolItem(id: 54, category: 'mat', icon: '🏗️', name: 'Concrete Mix Proportions', description: 'M15, M20, M25 dry volume batching'),
    ToolItem(id: 56, category: 'mat', icon: '🧱', name: 'Red Clay Bricks Count', description: '9" × 4.25" × 2.75" brickwork batches'),
    ToolItem(id: 58, category: 'mat', icon: '🔩', name: 'Steel Rebar Weight', description: 'D²/162 formula kg per meter weight'),
    ToolItem(id: 59, category: 'mat', icon: '📐', name: 'Reinforcement Steel Qty', description: 'Total tonnage for RCC elements'),
    ToolItem(id: 60, category: 'mat', icon: '✨', name: 'Tile Box Packaging', description: 'Square meters to retail tile cartons'),
    
    // BOQ & Cost
    ToolItem(id: 76, category: 'boq', icon: '🪙', name: 'BOQ Item Takeoff Builder', description: 'Quantity × Rate + Tax estimation'),
    ToolItem(id: 81, category: 'cost', icon: '🪙', name: 'Material Cost Estimator', description: 'Material line items with GST'),
    ToolItem(id: 82, category: 'cost', icon: '👷', name: 'Labour Wage Estimator', description: 'Daily worker count × wage rate'),
    ToolItem(id: 85, category: 'cost', icon: '🏗️', name: 'Total Construction Cost', description: 'Turnkey structural + finishing budget'),
    ToolItem(id: 88, category: 'cost', icon: '📐', name: 'Cost per Sq.Ft Analyzer', description: 'Budget breakdown per square foot'),
    ToolItem(id: 92, category: 'cost', icon: '🛡️', name: 'Contingency Reserve', description: '10% unforeseen site expense cushion'),
    
    // Slopes & Levels
    ToolItem(id: 96, category: 'slope', icon: '📉', name: 'Gradient & Percentage', description: '1 in X ratio to grade % and degrees'),
    ToolItem(id: 102, category: 'slope', icon: '💧', name: 'Drainage Pipe Gradient', description: 'Self-cleansing sewer pipe slope'),
    
    // Structural
    ToolItem(id: 108, category: 'struct', icon: '📏', name: 'Beam Section Geometry', description: 'L/12 deflection depth estimations'),
    ToolItem(id: 114, category: 'struct', icon: '📋', name: 'Bar Bending Schedule (BBS)', description: 'Cutting lengths & hook bend allowances'),
    
    // Electrical & Plumbing
    ToolItem(id: 119, category: 'elec', icon: '💡', name: 'Electrical Points Count', description: 'Sockets, light fixtures & fan points'),
    ToolItem(id: 121, category: 'elec', icon: '⚡', name: 'Connected Electrical Load', description: 'Total wattage & KW phase sizing'),
    ToolItem(id: 129, category: 'plumb', icon: '💧', name: 'Daily Water Consumption', description: 'NBC 135 LPCD occupants water demand'),
    ToolItem(id: 130, category: 'plumb', icon: '🛢️', name: 'Water Storage Tank Size', description: 'Overhead & underground sump capacity'),
    
    // Math Utilities
    ToolItem(id: 144, category: 'math', icon: '🧮', name: 'Basic Project Calculator', description: 'Standard arithmetic calculations'),
    ToolItem(id: 145, category: 'math', icon: '%', name: 'Percentage Variance', description: 'Tender vs actual budget differences'),
    
    // Site Logs
    ToolItem(id: 159, category: 'site', icon: '📑', name: 'Daily Progress Report (DPR)', description: 'Weather, labor headcount & daily pour'),
    ToolItem(id: 164, category: 'site', icon: '👷', name: 'Labor Muster Roll', description: 'Daily worker attendance muster'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCat = widget.initialCategory!;
    }
  }

  void _showCalculator(ToolItem tool) {
    showDialog(
      context: context,
      builder: (ctx) => _InteractiveCalculatorDialog(tool: tool),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter
    List<ToolItem> filtered = _allTools;
    if (_selectedCat == 'fav') {
      filtered = filtered.where((t) => _favorites.contains(t.id)).toList();
    } else if (_selectedCat != 'all') {
      filtered = filtered.where((t) => t.category == _selectedCat).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q))
          .toList();
    }

    final visible = filtered.take(_renderLimit).toList();

    return Scaffold(
      backgroundColor: darkBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '168 Engineering Tools',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Civil engineering, BOQ takeoffs, structural, and architectural calculators.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  // Search Box
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search concrete, steel, brick, tiles, FSI...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: goldAccent, size: 20),
                      filled: true,
                      fillColor: darkCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: darkBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: darkBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: goldAccent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 14),

                  // Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat.id == _selectedCat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${cat.icon} ${cat.name}'),
                            selected: isSelected,
                            selectedColor: goldAccent,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF0A1128)
                                  : Colors.white70,
                            ),
                            backgroundColor: darkCard,
                            side: BorderSide(
                              color: isSelected ? goldAccent : darkBorder,
                            ),
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
          visible.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '🔍 No matching tools found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = visible[index];
                        final isFav = _favorites.contains(tool.id);

                        return InkWell(
                          onTap: () => _showCalculator(tool),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: darkCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: darkBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: darkIconBg,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(tool.icon,
                                          style: const TextStyle(fontSize: 19)),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        isFav
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 19,
                                        color: isFav
                                            ? Colors.amber
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (isFav) {
                                            _favorites.remove(tool.id);
                                          } else {
                                            _favorites.add(tool.id);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  tool.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tool.description,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: visible.length,
                    ),
                  ),
                ),

          // Load More button
          if (filtered.length > _renderLimit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: goldAccent),
                    foregroundColor: goldAccent,
                  ),
                  onPressed: () =>
                      setState(() => _renderLimit += 30),
                  child: Text(
                    'LOAD MORE (${_renderLimit}/${filtered.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Interactive Calculator Modal Dialog ---
class _InteractiveCalculatorDialog extends StatefulWidget {
  final ToolItem tool;

  const _InteractiveCalculatorDialog({required this.tool});

  @override
  State<_InteractiveCalculatorDialog> createState() =>
      _InteractiveCalculatorDialogState();
}

class _InteractiveCalculatorDialogState
    extends State<_InteractiveCalculatorDialog> {
  final Map<String, TextEditingController> _ctrls = {};
  String _selectedShape = 'rect';
  String _selectedUnitFrom = 'feet';
  String _selectedUnitTo = 'meter';
  String? _resultValue;
  String? _resultUnit;
  String? _resultExtra;

  static const Color darkBg = Color(0xFF0A1128);
  static const Color darkCard = Color(0xFF131C35);
  static const Color goldAccent = Color(0xFFE5B05C);
  static const Color darkBorder = Color(0x33E5B05C);

  @override
  void initState() {
    super.initState();
    _initDefaults();
    _calculate();
  }

  void _initDefaults() {
    switch (widget.tool.id) {
      case 1: // Unit Converter
        _ctrls['val'] = TextEditingController(text: '100');
        break;
      case 2: // Area
      case 3: // Perimeter
      case 4: // Volume
        _ctrls['l'] = TextEditingController(text: '5.0');
        _ctrls['w'] = TextEditingController(text: '4.0');
        _ctrls['h'] = TextEditingController(text: '3.0');
        _ctrls['r'] = TextEditingController(text: '2.5');
        break;
      case 6: // Scale
        _ctrls['drawing'] = TextEditingController(text: '50');
        _ctrls['scale'] = TextEditingController(text: '100');
        break;
      case 8: // Slope
      case 96:
        _ctrls['rise'] = TextEditingController(text: '1');
        _ctrls['run'] = TextEditingController(text: '20');
        break;
      case 17: // Built-up
        _ctrls['carpet'] = TextEditingController(text: '800');
        _ctrls['walls'] = TextEditingController(text: '120');
        break;
      case 19: // FSI
        _ctrls['floor'] = TextEditingController(text: '3000');
        _ctrls['plot'] = TextEditingController(text: '2000');
        break;
      case 22: // Staircase
        _ctrls['height'] = TextEditingController(text: '3.0');
        _ctrls['riser'] = TextEditingController(text: '0.15');
        _ctrls['tread'] = TextEditingController(text: '0.28');
        break;
      case 28: // Excavation
      case 32: // Slab
        _ctrls['l'] = TextEditingController(text: '10');
        _ctrls['w'] = TextEditingController(text: '4');
        _ctrls['d'] = TextEditingController(text: '0.15');
        _ctrls['qty'] = TextEditingController(text: '1');
        break;
      case 36: // Brickwork
        _ctrls['l'] = TextEditingController(text: '5.0');
        _ctrls['h'] = TextEditingController(text: '3.0');
        _ctrls['t'] = TextEditingController(text: '0.23');
        break;
      case 41: // Tile
        _ctrls['area'] = TextEditingController(text: '25');
        _ctrls['tileSize'] = TextEditingController(text: '0.6');
        _ctrls['waste'] = TextEditingController(text: '5');
        break;
      case 43: // Paint
        _ctrls['area'] = TextEditingController(text: '60');
        _ctrls['coats'] = TextEditingController(text: '2');
        _ctrls['coverage'] = TextEditingController(text: '10');
        break;
      case 51: // Cement
      case 54: // Concrete
        _ctrls['vol'] = TextEditingController(text: '1.0');
        _ctrls['cRatio'] = TextEditingController(text: '1');
        _ctrls['sRatio'] = TextEditingController(text: '1.5');
        _ctrls['aRatio'] = TextEditingController(text: '3');
        break;
      case 58: // Steel Weight
        _ctrls['dia'] = TextEditingController(text: '12');
        _ctrls['len'] = TextEditingController(text: '12');
        break;
      case 76: // BOQ
      case 81: // Material Cost
        _ctrls['qty'] = TextEditingController(text: '100');
        _ctrls['rate'] = TextEditingController(text: '380');
        _ctrls['tax'] = TextEditingController(text: '18');
        break;
      case 82: // Labour
        _ctrls['workers'] = TextEditingController(text: '10');
        _ctrls['days'] = TextEditingController(text: '6');
        _ctrls['wage'] = TextEditingController(text: '800');
        break;
      case 88: // Cost per sqft
        _ctrls['cost'] = TextEditingController(text: '2400000');
        _ctrls['area'] = TextEditingController(text: '1200');
        break;
      case 129: // Water Demand
        _ctrls['occupants'] = TextEditingController(text: '5');
        _ctrls['lpcd'] = TextEditingController(text: '135');
        break;
      case 130: // Water Tank
        _ctrls['l'] = TextEditingController(text: '2.0');
        _ctrls['w'] = TextEditingController(text: '1.5');
        _ctrls['h'] = TextEditingController(text: '1.5');
        break;
      default:
        _ctrls['v1'] = TextEditingController(text: '10');
        _ctrls['v2'] = TextEditingController(text: '20');
    }
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _val(String key) => double.tryParse(_ctrls[key]?.text ?? '0') ?? 0.0;

  void _calculate() {
    setState(() {
      switch (widget.tool.id) {
        case 1: // Unit Converter
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
          _resultExtra = '$v $_selectedUnitFrom = $_resultValue $_selectedUnitTo';
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

        case 6: // Scale
          final d = _val('drawing');
          final s = _val('scale');
          final realMeters = (d * s) / 1000.0;
          _resultValue = '${realMeters.toStringAsFixed(2)} m';
          _resultUnit = 'Real World Length';
          _resultExtra = 'Scale 1:$s for ${d}mm on drawing';
          break;

        case 8: // Slope
        case 96:
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
          _resultUnit = 'sq.ft Built-up Area';
          _resultExtra = 'Carpet (${c} sq.ft) + Walls & Balconies (${w} sq.ft)';
          break;

        case 19: // FSI
          final f = _val('floor');
          final p = _val('plot');
          if (p > 0) {
            _resultValue = (f / p).toStringAsFixed(2);
            _resultUnit = 'FSI / FAR Index';
            _resultExtra = 'Total Covered Floor Area / Total Plot Area';
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
            _resultUnit = 'Staircase Flight Specs';
            _resultExtra = '$treads Treads • Total Horizontal Run: ${totalRun.toStringAsFixed(2)} m';
          }
          break;

        case 28: // Excavation
        case 32: // Slab
          final vol = _val('l') * _val('w') * _val('d') * (_val('qty') > 0 ? _val('qty') : 1.0);
          _resultValue = '${vol.toStringAsFixed(2)} m³';
          _resultUnit = 'Total Volume';
          _resultExtra = 'Approx ${(vol * 35.3147).toStringAsFixed(1)} cubic feet (cft)';
          break;

        case 36: // Brickwork
          final vol = _val('l') * _val('h') * _val('t');
          final bricks = (vol * 500).ceil();
          _resultValue = '$bricks Bricks';
          _resultUnit = 'Masonry Materials';
          _resultExtra = 'Wall volume: ${vol.toStringAsFixed(2)} m³ (at standard 500 bricks/m³)';
          break;

        case 41: // Tile
          final a = _val('area');
          final s = _val('tileSize');
          final w = _val('waste');
          if (s > 0) {
            final tileArea = s * s;
            final count = (a / tileArea) * (1 + w / 100.0);
            _resultValue = '${count.ceil()} Tiles';
            _resultUnit = 'Total Tiles Required';
            _resultExtra = 'Includes $w% cutting & breakage allowance';
          }
          break;

        case 43: // Paint
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

        case 51: // Cement
        case 54: // Concrete Mix
          final v = _val('vol');
          final c = _val('cRatio');
          final s = _val('sRatio');
          final a = _val('aRatio');
          final total = c + s + a;
          final dryVol = v * 1.54; // standard dry factor
          if (total > 0) {
            final cementM3 = (c / total) * dryVol;
            final bags = (cementM3 * 1440.0 / 50.0).ceil();
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
          _resultUnit = 'Rebar Weight';
          _resultExtra = 'D²/162 formula: ${wtPerM.toStringAsFixed(3)} kg/meter';
          break;

        case 76: // BOQ
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

        case 82: // Labour
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
          _resultUnit = 'Daily Water Demand';
          _resultExtra = '$occ persons at $lpcd Litres per capita (NBC standard)';
          break;

        case 130: // Water Tank
          final l = _val('l');
          final w = _val('w');
          final h = _val('h');
          final vol = l * w * h;
          final litres = vol * 1000.0;
          _resultValue = '${litres.toStringAsFixed(0)} Litres';
          _resultUnit = 'Tank Storage Capacity';
          _resultExtra = 'Internal Dimensions: ${vol.toStringAsFixed(2)} m³ volume';
          break;

        default:
          final v1 = _val('v1');
          final v2 = _val('v2');
          _resultValue = (v1 * v2).toStringAsFixed(2);
          _resultUnit = 'Output Value';
          _resultExtra = 'Computed based on parameters $v1 and $v2';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
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
                      color: darkIconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.tool.icon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tool.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.tool.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: darkBorder, height: 24),

              // Inputs based on Tool ID
              _buildInputs(),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldAccent,
                  foregroundColor: const Color(0xFF0A1128),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'CALCULATE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Result Card
              if (_resultValue != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: darkBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: goldAccent, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CALCULATION RESULT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _resultValue!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: goldAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_resultUnit != null)
                        Text(
                          _resultUnit!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
                    dropdownColor: darkCard,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
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
                    dropdownColor: darkCard,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
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
              dropdownColor: darkCard,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
      case 96:
        return Row(
          children: [
            Expanded(child: _buildField('rise', 'Vertical Rise (m)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('run', 'Horizontal Run (m)')),
          ],
        );

      case 17:
        return Row(
          children: [
            Expanded(child: _buildField('carpet', 'Carpet Area (sq.ft)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('walls', 'Walls & Balcony (sq.ft)')),
          ],
        );

      case 19:
        return Row(
          children: [
            Expanded(child: _buildField('floor', 'Total Floor Area (sq.ft)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('plot', 'Plot Area (sq.ft)')),
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

      case 41:
        return Column(
          children: [
            _buildField('area', 'Floor Area (sq.m)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('tileSize', 'Tile Side (m, e.g. 0.6)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('waste', 'Wastage (%)')),
              ],
            ),
          ],
        );

      case 43:
        return Column(
          children: [
            _buildField('area', 'Wall Surface Area (sq.m)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('coats', 'Number of Coats')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('coverage', 'Coverage (sq.m / L)')),
              ],
            ),
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
                Expanded(child: _buildField('cRatio', 'Cement')),
                const SizedBox(width: 8),
                Expanded(child: _buildField('sRatio', 'Sand')),
                const SizedBox(width: 8),
                Expanded(child: _buildField('aRatio', 'Aggregate')),
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
      controller: _ctrls[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        filled: true,
        fillColor: darkBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: goldAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
