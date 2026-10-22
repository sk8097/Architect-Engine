import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../constants/app_colors.dart";
import "../providers/app_state_provider.dart";
import "../providers/notification_provider.dart";
import "../widgets/app_drawer.dart";
import "home_screen.dart";
import "professional_screen.dart";
import "design_screen.dart";
import "tools_screen.dart";
import "notifications_screen.dart";

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    final List<Widget> screens = [
      HomeScreen(onNavigateTab: (idx) {
        setState(() => _currentIndex = idx);
      }),
      const ProfessionalScreen(),
      const DesignScreen(),
      const ToolsScreen(),
    ];

    final titles = [
      "ARCHITECT ENGINE",
      "PROFESSIONAL STUDIO",
      "DESIGN STUDIO",
      "TOOLS & UTILITIES",
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onSelectTab: (idx) {
          setState(() => _currentIndex = idx);
        },
      ),
      appBar: AppBar(
        leading: _currentIndex != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Home',
                onPressed: () => setState(() => _currentIndex = 0),
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Row(
          children: [
            const Text("📐", style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    child: Text(
                      "${notifProvider.unreadCount}",
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Text(appState.isDarkMode ? "🌙" : "☀️", style: const TextStyle(fontSize: 18)),
            onPressed: () => appState.toggleTheme(),
            tooltip: "Toggle Theme",
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
