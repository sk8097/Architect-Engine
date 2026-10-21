import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/unit_converter_screen.dart';
import '../screens/vastu_screen.dart';
import '../screens/tutorials_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/cloud_sync_screen.dart';
import '../screens/export_screen.dart';
import '../screens/share_screen.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_policy_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onSelectTab;

  const AppDrawer({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('👤', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Design • Plan • Build',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _buildSectionTitle('NAVIGATION'),
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.folder_outlined,
                    title: 'Projects',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(1);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.architecture,
                    title: 'Design Studio',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.handyman_outlined,
                    title: 'Tools & Utilities',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(3);
                    },
                  ),

                  const Divider(),
                  _buildSectionTitle('ACCOUNT'),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () => _nav(context, const ProfileScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.cloud_sync_outlined,
                    title: 'Cloud Sync',
                    onTap: () => _nav(context, const CloudSyncScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('APP PREFERENCES'),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, size: 22),
                    title: const Text('Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: Text(
                      appState.isDarkMode ? '🌙 Dark' : '☀️ Light',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkPrimary),
                    ),
                    onTap: () => appState.toggleTheme(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_outlined, size: 22),
                    title: const Text('Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<String>(
                      value: appState.currentLanguage,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                        DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                        DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી')),
                        DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                      ],
                      onChanged: (val) {
                        if (val != null) appState.setLanguage(val);
                      },
                    ),
                  ),

                  const Divider(),
                  _buildSectionTitle('SMART FEATURES'),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Notification Inbox',
                    onTap: () => _nav(context, const NotificationsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.straighten,
                    title: 'Unit Converter',
                    onTap: () => _nav(context, const UnitConverterScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.compass_calibration_outlined,
                    title: 'Vastu Guide',
                    onTap: () => _nav(context, const VastuScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.file_download_outlined,
                    title: 'Export Center',
                    onTap: () => _nav(context, const ExportScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('COMMUNITY & GUIDES'),
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: 'Tutorials',
                    onTap: () => _nav(context, const TutorialsScreen()),
                  ),

                  const Divider(),
                  _buildSectionTitle('SUPPORT & INFO'),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    onTap: () => _nav(context, const FAQScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    onTap: () => _nav(context, const ShareScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onTap: () => _nav(context, const AboutScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _nav(context, const PrivacyPolicyScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 12, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
