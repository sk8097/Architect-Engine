import 'package:flutter/material.dart';

// --- Professional Module Model ---
class ProCadModule {
  final int id;
  final String icon;
  final String title;
  final String subtitle;
  final String category; // 'CAD Tools', 'Standards', 'Documentation'
  final String status;
  final String description;
  final List<String> features;
  final String canvasSpecs;

  const ProCadModule({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.status,
    required this.description,
    required this.features,
    required this.canvasSpecs,
  });
}

class ProfessionalScreen extends StatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const Color darkBg = Color(0xFF0A1128);
  static const Color darkCard = Color(0xFF131C35);
  static const Color goldAccent = Color(0xFFE5B05C);
  static const Color darkBorder = Color(0x33E5B05C);
  static const Color darkIconBg = Color(0xFF1E293B);

  final List<String> _categories = [
    'All',
    'CAD Tools',
    'Standards & Layers',
    'Productivity & Docs'
  ];

  final List<ProCadModule> _modules = const [
    ProCadModule(
      id: 1,
      icon: '🖥️',
      title: 'CAD Studio',
      subtitle: 'Precision vector drawing workspace',
      category: 'CAD Tools',
      status: 'In Progress',
      description:
          'High-precision architectural drafting workspace with coordinate tracking, snap grids, polar tracking, and interactive vector manipulation.',
      features: [
        'Millimeter-precision coordinate input (Absolute & Relative X,Y)',
        'Object Snap (Endpoint, Midpoint, Center, Intersection, Perpendicular)',
        'Transform controls: Move, Copy, Rotate, Mirror, Offset, Trim, Extend',
        'Real-time dimension measurement HUD overlay during drafting',
        'Future DXF / DWG import, multi-layer rendering, and vector export'
      ],
      canvasSpecs:
          'Infinite vector canvas with dynamic zoom/pan, HUD coordinate indicator, snap guide lines, and contextual drafting toolbar.',
    ),
    ProCadModule(
      id: 2,
      icon: '✏️',
      title: 'Drawing Tools',
      subtitle: 'Parametric 2D shapes & geometry engine',
      category: 'CAD Tools',
      status: 'In Progress',
      description:
          'Comprehensive geometric shape suite for generating walls, structural footprints, openings, and architectural schematic symbols.',
      features: [
        'Orthogonal Lines, Continuous Polylines, Rectangles, and Arcs',
        'Architectural Hatching (Concrete, Brickwork, Earth, Insulation, Glass)',
        'Multi-level Undo / Redo engine with complete state restoration',
        'Object property inspector (stroke weight, dash style, layer linkage)',
        'Array duplication (Rectangular & Polar matrix layouts)'
      ],
      canvasSpecs:
          'Left toolbar with quick shape tools, bottom sheet controls for mobile screens, and floating parameter adjustment badge.',
    ),
    ProCadModule(
      id: 3,
      icon: '📚',
      title: 'Layers Manager',
      subtitle: 'Discipline-wise layer hierarchy',
      category: 'Standards & Layers',
      status: 'Planned',
      description:
          'Organize drawings across Architectural, Structural, Electrical, and Plumbing disciplines with fine-grained visibility and locking controls.',
      features: [
        'AIA & National Building Code (NBC) standard layer naming presets',
        'Instant layer visibility toggle (Show/Hide) and editing lock (Freeze)',
        'Per-layer color assignment, line types (Dashed, Centerline, Hidden), and lineweights',
        'Discipline grouping for one-tap MEP or structural isolation',
        'Export layer states to match municipal approval drawing standards'
      ],
      canvasSpecs:
          'Slide-up layer panel with color swatch picker, visibility eye toggles, padlock icons, and quick search filter.',
    ),
    ProCadModule(
      id: 4,
      icon: '📏',
      title: 'Dimensions & Scales',
      subtitle: 'Accurate architectural dimensioning',
      category: 'Standards & Layers',
      status: 'Planned',
      description:
          'Precision dimensioning tools ensuring drawings remain compliant with standard engineering scaling and municipal submission norms.',
      features: [
        'Linear, Aligned, Angular, Radius, and Continuous Baseline dimension chains',
        'Automatic scale-factor compensation for 1:50, 1:100, and 1:200 blueprints',
        'Dual metric/imperial readout (mm/meters alongside feet/inches)',
        'Customizable arrowheads, extension line offsets, and text positioning',
        'Dynamic dimension updates when linked geometry is edited'
      ],
      canvasSpecs:
          'On-screen snap handles with auto-align guides, readable orientation rules, and scale presets dropdown.',
    ),
    ProCadModule(
      id: 5,
      icon: '📝',
      title: 'Annotations & Labels',
      subtitle: 'Rich text, symbols & callouts',
      category: 'Standards & Layers',
      status: 'Planned',
      description:
          'Complete labeling system for room names, carpet areas, material tags, level markers, North arrows, and elevation benchmarks.',
      features: [
        'Smart Room Tagging: auto-calculates and displays room area dynamically',
        'Multi-leader callout arrows for material and construction specifications',
        'Standard architectural symbol library (North Arrows, Section Cuts, Level Marks)',
        'Configurable font sizes calibrated to sheet printing scales',
        'Auto-generated drawing legends and abbreviation glossaries'
      ],
      canvasSpecs:
          'Floating text formatting bar, symbol picker dialog, and automatic text orientation adjustment.',
    ),
    ProCadModule(
      id: 6,
      icon: '📋',
      title: 'Sheet Templates',
      subtitle: 'Standard title blocks & paper sizes',
      category: 'Standards & Layers',
      status: 'Planned',
      description:
          'Standardized architectural drawing title blocks and sheet boundaries conforming to ISO A0/A1/A2/A3/A4 formats.',
      features: [
        'Pre-configured Title Blocks with client name, project ID, date, and revisions',
        'Standard sheet margins, folding marks, and drawing registers',
        'Multiple viewports support on a single printable sheet layout',
        'Corporate branding logo placeholder and engineer/architect seal area',
        'Save custom studio templates for quick deployment on new projects'
      ],
      canvasSpecs:
          'Print preview workbench with viewport boundary toggles and paper layout navigator.',
    ),
    ProCadModule(
      id: 7,
      icon: '⚖️',
      title: 'Drafting Standards',
      subtitle: 'NBC & municipal code compliance',
      category: 'Standards & Layers',
      status: 'Planned',
      description:
          'Built-in rulebook enforcing line thicknesses, font conventions, and minimum spatial clearances mandated by building bylaws.',
      features: [
        'Pre-loaded National Building Code (NBC) pen weight assignments',
        'Minimum doorway, staircase, and corridor width compliance warnings',
        'Standard drafting line conventions (cut lines, projection lines, hidden lines)',
        'Municipal sanction sheet checklist and pre-submission audit',
        'Export compliance report summarizing drawing specifications'
      ],
      canvasSpecs:
          'Bylaws check card with pass/warning indicators and recommended standard adjustment values.',
    ),
    ProCadModule(
      id: 8,
      icon: '⚡',
      title: 'Productivity Suite',
      subtitle: 'Quick shortcuts & command history',
      category: 'Productivity & Docs',
      status: 'Planned',
      description:
          'Speed up repetitive drafting workflows with quick actions, command history, and keyboard/gesture accelerator shortcuts.',
      features: [
        'Repeat Last Command via single tap or spacebar gesture',
        'Searchable command palette and quick action toolbar',
        'Audit history log of all drafting operations with timestamps',
        'Customizable touch gestures (pinch-zoom, two-finger pan, double-tap reset)',
        'One-tap favorite tools pinboard'
      ],
      canvasSpecs:
          'Top ribbon of recent operations, floating quick-properties panel, and customizable shortcut mapper.',
    ),
    ProCadModule(
      id: 9,
      icon: '📑',
      title: 'Documentation Register',
      subtitle: 'Drawing register & batch export',
      category: 'Productivity & Docs',
      status: 'Planned',
      description:
          'Master index managing sheet numbers (A-101 to E-105), issue dates, revision histories, and direct batch PDF/DXF distribution.',
      features: [
        'Systematic sheet numbering (A-Architectural, S-Structural, M-MEP)',
        'Revision control tracking (Revision notes, date, approved by)',
        'Drawing issue status management (Preliminary, Sanction, GFC - Good for Construction)',
        'High-resolution vector PDF export with selectable layer sets',
        'Bill of Quantities (BOQ) cross-referencing and sheet index printing'
      ],
      canvasSpecs:
          'Table-view register of all project sheets with status badges and one-tap batch PDF generator.',
    ),
  ];

  void _showModuleDetails(ProCadModule module) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: darkIconBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: darkBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(module.icon,
                            style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              module.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Status Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: module.status == 'In Progress'
                            ? Colors.blue.withOpacity(0.18)
                            : goldAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: module.status == 'In Progress'
                              ? Colors.blueAccent
                              : goldAccent,
                        ),
                      ),
                      child: Text(
                        'Status: ${module.status}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: module.status == 'In Progress'
                              ? Colors.lightBlueAccent
                              : goldAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Overview
                  const Text(
                    '📌 Description & Scope',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: goldAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: darkBorder),
                    ),
                    child: Text(
                      module.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Specific Features
                  const Text(
                    '🎯 Engineering Capabilities',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: goldAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...module.features.map(
                    (feat) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✓ ',
                            style: TextStyle(
                              color: goldAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              feat,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Canvas Specs
                  const Text(
                    '📐 Interface & Workspace Specs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: goldAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: darkBorder),
                    ),
                    child: Text(
                      module.canvasSpecs,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldAccent,
                      foregroundColor: const Color(0xFF0A1128),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${module.title} workspace initialized in precision mode.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.architecture),
                    label: Text(
                      'OPEN ${module.title.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
      final matchesSearch =
          m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              m.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              m.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          m.category.toLowerCase().contains(_selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: goldAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PROFESSIONAL CAD STUDIO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: goldAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Precision • Control • Standards',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vector drafting, municipal standard layers, NBC compliance & sheet document sets.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search CAD modules, layers, templates...',
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
              onChanged: (val) => setState(() => _searchQuery = val),
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
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
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
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Engineering Modules',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${filtered.length} modules',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Modules Grid
            filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        '🔍 No modules match your search query',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      return InkWell(
                        onTap: () => _showModuleDetails(m),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: darkIconBg,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(m.icon,
                                        style: const TextStyle(fontSize: 18)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: m.status == 'In Progress'
                                          ? Colors.blue.withOpacity(0.18)
                                          : goldAccent.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.status == 'In Progress'
                                          ? 'Active'
                                          : 'Planned',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: m.status == 'In Progress'
                                            ? Colors.lightBlueAccent
                                            : goldAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                m.title,
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
                                m.subtitle,
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
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
