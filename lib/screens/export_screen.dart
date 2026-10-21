import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  void _export(BuildContext context, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting project in $format format... Ready!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Center')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTile(context, '📄 PDF Document', 'Print-ready A3/A4 architectural drawing sets', 'PDF'),
            const SizedBox(height: 12),
            _buildTile(context, '📐 CAD / DXF Format', 'AutoCAD and vector CAD compatible entities', 'DXF'),
            const SizedBox(height: 12),
            _buildTile(context, '🖼️ High-Res Image', 'Rendered PNG/JPG elevation and plan visualizations', 'Image'),
            const SizedBox(height: 12),
            _buildTile(context, '📊 BOQ Spreadsheet', 'Itemized material quantity takeoff in CSV/Excel', 'CSV'),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, String sub, String fmt) {
    return ListTile(
      tileColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.darkBorder)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.download),
      onTap: () => _export(context, fmt),
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
            const Text('Help fellow architects, civil engineers, and homeowners build smarter.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('https://architectengine.app', style: TextStyle(fontSize: 13))),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'https://architectengine.app'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: const [
                  Text('🏠', style: TextStyle(fontSize: 52)),
                  SizedBox(height: 10),
                  Text('ARCHITECT ENGINE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Design • Plan • Build • Smarter', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Version 1.0.0', style: TextStyle(fontSize: 11, color: AppColors.darkPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('🎯 Our Mission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkPrimary)),
            const SizedBox(height: 6),
            const Text('To make professional architectural design and civil engineering calculation accessible to everyone — homeowners, students, contractors, and architects.', style: TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 18),
            const Text('✨ What We Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkPrimary)),
            const SizedBox(height: 6),
            const Text('• 168 Engineering, Architectural & BOQ Calculation Tools\n• 11 Coordinated Architectural Design Modules\n• 9 Professional CAD Drafting & Standard Specifications\n• Built-in Vastu Shastra Guidelines\n• Multi-Language Support (English, Hindi, Marathi, Gujarati, Tamil)', style: TextStyle(fontSize: 13, height: 1.6)),
            const SizedBox(height: 24),
            Center(child: Text('Made with ❤️ in India', style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Privacy Policy for Architect Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Last updated: January 2025 • Version 1.0\n\n'
                '1. Information We Collect: Project dimensional records, user profile preferences, and tool settings stored on your device.\n\n'
                '2. Data Security: All design records remain private on your device unless you explicitly opt to backup to your personal Google Drive.\n\n'
                '3. Third-Party Sharing: We never monetize or sell personal drawing data to third parties.\n\n'
                '4. Offline Priority: Core engineering calculations run completely locally without transferring data to external servers.',
                style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
