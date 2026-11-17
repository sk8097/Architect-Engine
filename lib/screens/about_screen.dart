import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Architect Engine')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Icon(Icons.architecture, size: 64),
          SizedBox(height: 16),
          Text('Architect Engine', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Mobile architectural workspace for project planning, CAD drafting, '
              'construction calculators, and design references.',
              textAlign: TextAlign.center),
          SizedBox(height: 24),
          Text('Important', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Generated layouts and calculations are preliminary aids. They are not '
              'certified architectural, structural, or municipal approvals. Have plans '
              'checked by a qualified professional against the regulations applicable '
              'to the project location before construction.'),
        ],
      ),
    );
  }
}
