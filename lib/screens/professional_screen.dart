import 'package:flutter/material.dart';

class ProfessionalScreen extends StatelessWidget {
  const ProfessionalScreen({super.key});

  final List<Map<String, String>> tools = const [
    {'icon': '🖥️', 'name': 'CAD Workspace', 'sub': 'Snap, grid, trim, extend & offset'},
    {'icon': '✏️', 'name': 'Vector Tools', 'sub': 'Polyline, arc, hatch & duplicate'},
    {'icon': '📚', 'name': 'Layer Manager', 'sub': 'Architectural, MEP & Structural layers'},
    {'icon': '📏', 'name': 'Precision Dimensions', 'sub': 'Aligned, linear & angular annotation'},
    {'icon': '🏷️', 'name': 'Drawing Legends', 'sub': 'Room stamps & automated tags'},
    {'icon': '📑', 'name': 'Title Blocks', 'sub': 'Standard A3/A4 title sheets'},
    {'icon': '⚖️', 'name': 'NBC Standards', 'sub': 'National Building Code compliance'},
    {'icon': '⚡', 'name': 'Command Shortcuts', 'sub': 'Hotkeys & rapid repeat action'},
    {'icon': '📄', 'name': 'Sheet Register', 'sub': 'Revision history & DXF/PDF export'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final t = tools[index];
        return Card(
          color: const Color(0xFF131C35),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: Text(t['icon']!, style: const TextStyle(fontSize: 24)),
            title: Text(t['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(t['sub']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE5B05C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFE5B05C))),
            ),
          ),
        );
      },
    );
  }
}
