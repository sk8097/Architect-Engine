import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';

class CloudSyncScreen extends StatelessWidget {
  const CloudSyncScreen({super.key});

  void _showUnavailable(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Google Drive sync not configured'),
        content: const Text(
          'This build stores project data locally on the device. '
          'Google OAuth, upload, download, and conflict handling are not implemented yet. '
          'No Google account has been connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync & Storage')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: appState.storageType == 'local'
                      ? AppColors.darkPrimary
                      : AppColors.darkBorder,
                ),
              ),
              tileColor: Theme.of(context).cardColor,
              leading: const Text('📱', style: TextStyle(fontSize: 24)),
              title: const Text('Local Device Storage',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Project data is stored on this device',
                  style: TextStyle(fontSize: 11)),
              trailing: appState.storageType == 'local'
                  ? const Icon(Icons.check_circle, color: AppColors.darkPrimary)
                  : null,
              onTap: () => appState.setStorageType('local'),
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
              tileColor: Theme.of(context).cardColor,
              leading: const Text('☁️', style: TextStyle(fontSize: 24)),
              title: const Text('Google Drive Backup',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Not configured in this build',
                  style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.cloud_off_outlined),
              onTap: () => _showUnavailable(context),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimary,
                foregroundColor: const Color(0xFF0A1128),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: null,
              icon: const Icon(Icons.sync_disabled),
              label: const Text('CLOUD SYNC UNAVAILABLE',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
