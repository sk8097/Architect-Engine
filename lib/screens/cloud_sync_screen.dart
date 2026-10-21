import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';

class CloudSyncScreen extends StatelessWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync & Storage')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: appState.storageType == 'local' ? AppColors.darkPrimary : AppColors.darkBorder),
              ),
              tileColor: Theme.of(context).cardColor,
              leading: const Text('📱', style: TextStyle(fontSize: 24)),
              title: const Text('Local Device Storage', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Keep designs stored privately on this device', style: TextStyle(fontSize: 11)),
              trailing: appState.storageType == 'local' ? const Icon(Icons.check_circle, color: AppColors.darkPrimary) : null,
              onTap: () => appState.setStorageType('local'),
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: appState.storageType == 'gdrive' ? AppColors.darkPrimary : AppColors.darkBorder),
              ),
              tileColor: Theme.of(context).cardColor,
              leading: const Text('☁️', style: TextStyle(fontSize: 24)),
              title: const Text('Google Drive Backup', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(appState.gdriveConnected ? 'Connected: ${appState.gdriveEmail}' : 'Sync project files directly to your Drive', style: const TextStyle(fontSize: 11)),
              trailing: appState.storageType == 'gdrive' ? const Icon(Icons.check_circle, color: AppColors.darkPrimary) : null,
              onTap: () {
                if (appState.gdriveConnected) {
                  appState.disconnectGDrive();
                } else {
                  appState.connectGDrive('user@gmail.com');
                }
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimary,
                foregroundColor: const Color(0xFF0A1128),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔄 Cloud sync completed successfully!')),
                );
              },
              icon: const Icon(Icons.sync),
              label: const Text('SYNC NOW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
