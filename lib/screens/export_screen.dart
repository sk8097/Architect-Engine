import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'cad_editor_screen.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  void _openCadExport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CadEditorScreen(projectTitle: 'Drawing1'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Center')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CAD drawing export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  'Open the CAD editor to export the current Drawing1 workspace. '
                  'The editor currently supports DXF and PDF sharing. Draw or open your saved workspace first.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            leading: const Icon(Icons.edit_document, color: AppColors.darkPrimary),
            title: const Text('Open CAD Editor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text('Create or edit a drawing, then share it as DXF or PDF', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => _openCadExport(context),
          ),
        ],
      ),
    );
  }
}

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share App')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('📢', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Share Architect Engine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Help fellow architects, civil engineers, and homeowners build smarter.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _shareApp(context),
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    // Sharing the application binary/link is intentionally not fabricated here.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('App link unavailable'),
        content: const Text('A verified public download link has not been configured yet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }
}
