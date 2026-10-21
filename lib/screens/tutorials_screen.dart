import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/tutorials_data.dart';

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
