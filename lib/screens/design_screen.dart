import 'package:flutter/material.dart';

class DesignScreen extends StatefulWidget {
  const DesignScreen({super.key});

  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

class _DesignScreenState extends State<DesignScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  // Theme Constants (Dark Architectural Theme)
  static const Color darkBg = Color(0xFF0A1128);
  static const Color darkCard = Color(0xFF131C35);
  static const Color darkPrimary = Color(0xFFE5B05C); // Gold Accent
  static const Color darkBorder = Color(0x33E5B05C);
  static const Color darkIconBg = Color(0xFF1E293B);
  static const Color statusProgressBg = Color(0x263B82F6);
  static const Color statusProgressText = Color(0xFF3B82F6);
  static const Color statusPlannedBg = Color(0x26E5B05C);
  static const Color statusPlannedText = Color(0xFFE5B05C);

  // 11 Architectural Modules from Design Studio
  final List<Map<String, dynamic>> _modules = [
    {
      'id': 1,
      'name': 'Floor Plan',
      'icon': '📐',
      'category': 'Architectural',
      'status': 'In Progress',
      'desc': 'Room layouts & architectural spatial arrangement',
      'full': 'Building ka primary architectural layout, room boundaries, internal dimensions, wall thicknesses, aur door/window placements.',
      'specs': ['Standard Scale: 1:100 / 1:50', 'NBC Room Area Compliance', 'Door Swing & Window Schedules', 'Carpet & Built-up Calculation'],
      'scale': '1:100'
    },
    {
      'id': 2,
      'name': 'Site Plan',
      'icon': '🏞️',
      'category': 'Spatial & Site',
      'status': 'Planned',
      'desc': 'Plot & site zoning and landscape coordinates',
      'full': 'Building ko pure plot aur surroundings mein position karna, setback clearances, road access, setback margins, aur North orientation.',
      'specs': ['Municipal Setback Verification', 'Access Road Width 9m/12m', 'FSI & Ground Coverage', 'Plot Boundary Coordinates'],
      'scale': '1:200'
    },
    {
      'id': 3,
      'name': 'Elevation',
      'icon': '🏛️',
      'category': 'Architectural',
      'status': 'Planned',
      'desc': 'Exterior views, facade treatments & levels',
      'full': 'Front, rear, aur side exterior elevations showing facade architectural styling, sill/lintel heights, parapet, aur floor-to-floor heights.',
      'specs': ['Plinth & Parapet Levels', 'Window Sill & Lintel Heights', 'Facade Material Finishing', 'Sunshade / Chhajja Projections'],
      'scale': '1:100'
    },
    {
      'id': 4,
      'name': 'Section',
      'icon': '📏',
      'category': 'Architectural',
      'status': 'Planned',
      'desc': 'Vertical cuts through building structural levels',
      'full': 'Building ke through vertical cut showing slab thickness, foundation depth, staircase headroom, beam drops, aur roof waterproofing levels.',
      'specs': ['Slab Thickness & Beam Drops', 'Staircase Riser & Tread Profile', 'Foundation Depth & Plinth Filling', 'Clear Ceiling Height (2.9m+)'],
      'scale': '1:50'
    },
    {
      'id': 5,
      'name': '3D View',
      'icon': '📦',
      'category': 'Spatial & Site',
      'status': 'Planned',
      'desc': 'Spatial volumetric 3D representation',
      'full': '3D volumetric massing model, daylight shadow simulations, exterior texturing, aur interactive walkthrough spatial visualizations.',
      'specs': ['Volumetric Spatial Massing', 'Daylight & Sun Path Study', 'Isometric Axonometric Views', 'Material & Texture Finishes'],
      'scale': 'Isometric'
    },
    {
      'id': 6,
      'name': 'Interior',
      'icon': '🛋️',
      'category': 'Spatial & Site',
      'status': 'Planned',
      'desc': 'Spaces, furniture layouts & finishes',
      'full': 'Room-wise interior spatial planning, furniture circulation clearances, false ceiling layouts, electrical appliances, aur floor finishes.',
      'specs': ['Furniture Clearance Dimensions', 'False Ceiling Reflected Plan', 'Flooring Tile / Marble Patterns', 'Modular Kitchen & Wardrobe Layouts'],
      'scale': '1:50'
    },
    {
      'id': 7,
      'name': 'Landscape',
      'icon': '🌳',
      'category': 'Spatial & Site',
      'status': 'Planned',
      'desc': 'Outdoor design, paving & planting layout',
      'full': 'Outdoor hardscape aur softscape design, driveway interlocking pavers, garden zones, rain water harvesting trenches, aur boundary wall gate design.',
      'specs': ['Permeable Paver Driveways', 'Vastu Tulsi & Plant Zones', 'Perimeter Stormwater Drainage', 'Outdoor Accent Lighting Points'],
      'scale': '1:200'
    },
    {
      'id': 8,
      'name': 'Structural',
      'icon': '🏗️',
      'category': 'Structural & MEP',
      'status': 'Planned',
      'desc': 'Structural engineering & frame coordination',
      'full': 'Column-beam grid arrangement, footing centerlines, column sizes, slab reinforcement rebar schedules, aur structural engineer coordination.',
      'specs': ['Column Centerline Grid', 'Isolated Footing Schedule', 'Plinth Beam & Lintel Bands', 'Rebar Steel Weight Takeoff'],
      'scale': '1:50'
    },
    {
      'id': 9,
      'name': 'Electrical',
      'icon': '⚡',
      'category': 'Structural & MEP',
      'status': 'Planned',
      'desc': 'Power conduits, fixtures & circuit loads',
      'full': 'Lighting fixtures, 6A/16A power socket points, switchboard elevations, wall conduit pathways, Distribution Board (DB) routing, aur load schedule.',
      'specs': ['Lighting & Fan Point Schedule', 'Power Outlets (AC, Geyser, Fridge)', 'Conduit In-Slab Pathways', 'Main DB Load Phase Balancing'],
      'scale': '1:100'
    },
    {
      'id': 10,
      'name': 'Plumbing',
      'icon': '🚰',
      'category': 'Structural & MEP',
      'status': 'Planned',
      'desc': 'Water supply, drainage & sanitary lines',
      'full': 'Potable cold/hot water distribution lines, sanitary soil/waste drainage slope routes, inspection chambers, aur overhead tank capacity sizing.',
      'specs': ['Soil & Waste Pipe Slopes (1:40)', 'Overhead Tank Sizing (135 LPCD)', 'Inspection Chamber Routing', 'Rainwater Harvesting Recharge'],
      'scale': '1:100'
    },
    {
      'id': 11,
      'name': 'Coordinated Drawings',
      'icon': '📋',
      'category': 'Structural & MEP',
      'status': 'Planned',
      'desc': 'Drawing sets, revision control & BIM coordination',
      'full': 'Integrated composite overlay preventing MEP pipes vs Structural beam clashes, drawing register tracking, revision history, aur municipal submission sets.',
      'specs': ['Multi-Discipline Clash Detection', 'Drawing Register (A-101 to E-105)', 'Revision Control (R0, R1, R2)', 'Municipal Sanction Drawing Set'],
      'scale': 'Multi-Sheet'
    },
  ];

  void _showModuleDetails(BuildContext context, Map<String, dynamic> mod) {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final List<String> specs = List<String>.from(mod['specs'] ?? []);
        final bool isProgress = mod['status'] == 'In Progress';

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: darkIconBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: darkBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(mod['icon'], style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mod['name'],
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${mod['category']} • Scale ${mod['scale']}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isProgress ? statusProgressBg : statusPlannedBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          mod['status'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isProgress ? statusProgressText : statusPlannedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Overview Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: darkBorder),
                    ),
                    child: Text(
                      mod['full'],
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Architectural Specifications
                  const Text(
                    '🎯 Key Specifications & Standards',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary),
                  ),
                  const SizedBox(height: 10),
                  ...specs.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✓ ', style: TextStyle(color: darkPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                            Expanded(
                              child: Text(item, style: const TextStyle(fontSize: 12, color: Colors.white60, height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),

                  // Action Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPrimary,
                      foregroundColor: darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('📐 ${mod['name']} canvas editor loading...'),
                          backgroundColor: darkCard,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_document, size: 18),
                    label: Text(
                      'OPEN ${mod['name'].toString().toUpperCase()} STUDIO',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
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
    final filtered = _modules.where((m) {
      final matchesCategory = _selectedCategory == 'All' || m['category'] == _selectedCategory;
      final matchesSearch = m['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m['desc'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [darkCard, darkBg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: darkPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DESIGN STUDIO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: darkPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Turn concepts into\ncoordinated designs.',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate architectural plans, structural schematics, MEP services, and 3D perspectives according to NBC standards.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search design modules (e.g. floor plan, elevation, beam)...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 20, color: darkPrimary),
                filled: true,
                fillColor: darkCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: darkBorder),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 14),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All'),
                  _buildCategoryChip('Architectural'),
                  _buildCategoryChip('Structural & MEP'),
                  _buildCategoryChip('Spatial & Site'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Design Modules',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${filtered.length} of ${_modules.length} active',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Modules 2-Column Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final module = filtered[index];
                final bool isProgress = module['status'] == 'In Progress';

                return InkWell(
                  onTap: () => _showModuleDetails(context, module),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: darkIconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(module['icon'], style: const TextStyle(fontSize: 20)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isProgress ? statusProgressBg : statusPlannedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                module['status'],
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isProgress ? statusProgressText : statusPlannedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          module['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          module['desc'],
                          style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title) {
    final bool isSelected = _selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(title),
        selected: isSelected,
        selectedColor: darkPrimary,
        backgroundColor: darkCard,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? darkBg : Colors.white70,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? darkPrimary : darkBorder),
        ),
        onSelected: (_) => setState(() => _selectedCategory = title),
      ),
    );
  }
}
