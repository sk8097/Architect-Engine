import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/design_data.dart';
import '../models/module_models.dart';

class DesignScreen extends StatelessWidget {
  const DesignScreen({super.key});

  void _showModuleDetails(BuildContext context, DesignModule module) {
    final details = DesignData.moduleDetails[module.id] ?? {
      'name': 'Design Module',
      'desc': 'Architectural engineering module',
      'full': 'Building coordinated drawings and layouts.',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: Text(module.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(details['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(details['desc']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(
                  details['full']!,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🚧', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Interactive Editor In Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Full vector drawing and CAD editing tools are in active development.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
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
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkIconBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('DESIGN STUDIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkPrimary)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Turn concepts into coordinated designs.', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Start a design, review floor plans, or inspect building module specifications.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text('Design Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${DesignData.modules.length} modules', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
              itemCount: DesignData.modules.length,
              itemBuilder: (context, index) {
                final module = DesignData.modules[index];
                final details = DesignData.moduleDetails[module.id] ?? {'name': 'Module', 'desc': ''};

                return InkWell(
                  onTap: () => _showModuleDetails(context, module),
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
                              child: Text(module.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: module.status == 'progress'
                                    ? AppColors.statusProgressBg
                                    : AppColors.statusPlannedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                module.status == 'progress' ? 'In Progress' : 'Planned',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: module.status == 'progress'
                                      ? AppColors.statusProgressText
                                      : AppColors.statusPlannedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(details['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(details['desc']!, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
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
