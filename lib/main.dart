import 'package:flutter/material.dart';

void main() {
  runApp(const ArchitectEngineApp());
}

class ArchitectEngineApp extends StatefulWidget {
  const ArchitectEngineApp({super.key});

  @override
  State<ArchitectEngineApp> createState() => _ArchitectEngineAppState();
}

class _ArchitectEngineAppState extends State<ArchitectEngineApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DesignScreen(),
    ProfessionalScreen(),
    ToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Architect Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1128),
        cardColor: const Color(0xFF131C35),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE5B05C),
          surface: Color(0xFF131C35),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1128),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Text('🏛️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text('ARCHITECT ENGINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: const Color(0xFF131C35),
          indicatorColor: const Color(0xFFE5B05C).withOpacity(0.2),
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.architecture), label: 'Design'),
            NavigationDestination(icon: Icon(Icons.draw_outlined), selectedIcon: Icon(Icons.draw), label: 'CAD Studio'),
            NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'Tools'),
          ],
        ),
      ),
    );
  }
}

