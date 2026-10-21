import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/vastu_data.dart';

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
