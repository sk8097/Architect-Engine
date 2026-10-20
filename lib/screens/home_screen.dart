import 'package:flutter/material.dart';

// Project Data Model
class ProjectItem {
  final String id;
  String name;
  double length;
  double width;
  String bhk;
  String floors;
  String facing;

  ProjectItem({
    required this.id,
    required this.name,
    required this.length,
    required this.width,
    required this.bhk,
    required this.floors,
    required this.facing,
  });

  double get areaSqFt => length * width;
}

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Theme Colors
  static const Color goldColor = Color(0xFFE5B05C);
  static const Color cardColor = Color(0xFF131C35);
  static const Color iconBgColor = Color(0xFF1E293B);
  static const Color borderColor = Color(0x33E5B05C);

  // Sample initial projects
  final List<ProjectItem> _projects = [
    ProjectItem(
      id: '1',
      name: 'Sharma Villa',
      length: 40,
      width: 30,
      bhk: '3 BHK',
      floors: 'G+1',
      facing: 'East',
    ),
  ];

  void _showProjectDialog({ProjectItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final lengthCtrl = TextEditingController(text: existing != null ? existing.length.toString() : '40');
    final widthCtrl = TextEditingController(text: existing != null ? existing.width.toString() : '30');
    String bhkVal = existing?.bhk ?? '2 BHK';
    String floorVal = existing?.floors ?? 'Ground floor';
    String facingVal = existing?.facing ?? 'East';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: borderColor),
              ),
              title: Text(
                existing == null ? 'Create New Project' : 'Edit Project',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Project Name',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lengthCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Length (ft)',
                              labelStyle: TextStyle(color: Colors.grey),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: widthCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Width (ft)',
                              labelStyle: TextStyle(color: Colors.grey),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: bhkVal,
                      dropdownColor: cardColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'BHK Type', labelStyle: TextStyle(color: Colors.grey)),
                      items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Custom']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => bhkVal = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: facingVal,
                      dropdownColor: cardColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Facing (Vastu)', labelStyle: TextStyle(color: Colors.grey)),
                      items: ['North', 'East', 'South', 'West', 'North-East', 'South-East']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => facingVal = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: const Color(0xFF0A1128),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final l = double.tryParse(lengthCtrl.text) ?? 30.0;
                    final w = double.tryParse(widthCtrl.text) ?? 40.0;
                    final name = nameCtrl.text.trim().isEmpty ? 'My Project' : nameCtrl.text.trim();

                    setState(() {
                      if (existing != null) {
                        existing.name = name;
                        existing.length = l;
                        existing.width = w;
                        existing.bhk = bhkVal;
                        existing.floors = floorVal;
                        existing.facing = facingVal;
                      } else {
                        _projects.insert(
                          0,
                          ProjectItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            length: l,
                            width: w,
                            bhk: bhkVal,
                            floors: floorVal,
                            facing: facingVal,
                          ),
                        );
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Save Project' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ARCHITECTURAL WORKSPACE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: goldColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Turn your ideas into\nprofessional drawings.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Spatial floor planning, CAD modules, and civil engineering takeoff calculations.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: const Color(0xFF0A1128),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showProjectDialog(),
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

            // Projects Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Projects',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${_projects.length} Saved',
                  style: const TextStyle(fontSize: 12, color: goldColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_projects.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Text('No projects yet. Tap "+ Create New Project"', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._projects.map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: goldColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🏛️', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.bhk} • ${p.floors} • ${p.facing} Facing',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.length} × ${p.width} ft (${p.areaSqFt.toStringAsFixed(0)} sq.ft)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: goldColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => _projects.removeWhere((item) => item.id == p.id)),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Quick Studio Shortcuts
            const Text(
              'Studio Modules',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildShortcut('📐', 'Floor Plan', 'Spatial layouts', () => widget.onNavigateTab?.call(1)),
                _buildShortcut('🏞️', 'Site Plan', 'Plot & setbacks', () => widget.onNavigateTab?.call(1)),
                _buildShortcut('🏗️', 'CAD Tools', 'Drafting standards', () => widget.onNavigateTab?.call(2)),
                _buildShortcut('🧮', '168 Tools', 'Civil calculations', () => widget.onNavigateTab?.call(3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut(String icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
