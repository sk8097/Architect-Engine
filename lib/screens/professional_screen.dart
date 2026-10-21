import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/professional_data.dart';
import '../models/module_models.dart';

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
