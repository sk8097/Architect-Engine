import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/faq_data.dart';

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
