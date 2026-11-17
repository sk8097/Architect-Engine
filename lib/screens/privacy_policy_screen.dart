import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Local storage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('This build stores project records, preferences, and profile fields '
              'locally on the device using application preferences. Uninstalling the '
              'app or clearing its data may remove locally stored information.'),
          SizedBox(height: 20),
          Text('Cloud services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Google Drive authentication and cloud backup are not implemented in '
              'this build. The app must not display a connected cloud account or claim '
              'that a cloud sync has completed.'),
          SizedBox(height: 20),
          Text('Professional review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Architectural drawings and calculator results are preliminary tools. '
              'They should be reviewed by a qualified professional before being used '
              'for permitting or construction.'),
        ],
      ),
    );
  }
}
