import 'package:flutter/material.dart';

class DesignScreen extends StatelessWidget {
  const DesignScreen({super.key});

  final List<Map<String, String>> modules = const [
    {'icon': '📐', 'title': 'Floor Plan', 'desc': 'Detailed dimensions & room layouts'},
    {'icon': '🏞️', 'title': 'Site Plan', 'desc': 'Plot zoning & orientation'},
    {'icon': '🏛️', 'title': 'Elevation', 'desc': 'Exterior facade & sill heights'},
    {'icon': '📏', 'title': 'Section', 'desc': 'Vertical slab & ceiling cuts'},
    {'icon': '🧊', 'title': '3D View', 'desc': 'Interactive 3D volumetric massing'},
    {'icon': '🛋️', 'title': 'Interior', 'desc': 'Furniture clearances & finishes'},
    {'icon': '🌿', 'title': 'Landscape', 'desc': 'Garden, paving & drainage'},
    {'icon': '🏗️', 'title': 'Structural', 'desc': 'Column-beam grid & footings'},
    {'icon': '⚡', 'title': 'Electrical', 'desc': 'Light points, conduits & load'},
    {'icon': '🚰', 'title': 'Plumbing', 'desc': 'Water supply & sanitary lines'},
    {'icon': '📋', 'title': 'Coordinated Set', 'desc': 'BIM drawing registry & exports'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];
        return Card(
          color: const Color(0xFF131C35),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.white10),
          ),
          child: ListTile(
            leading: Text(m['icon']!, style: const TextStyle(fontSize: 26)),
            title: Text(m['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(m['desc']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFE5B05C)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${m['title']} module selected')),
              );
            },
          ),
        );
      },
    );
  }
}
