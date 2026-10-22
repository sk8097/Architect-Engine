import 'screens/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_themes.dart';
import 'providers/app_state_provider.dart';
import 'providers/project_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const ArchitectEngineApp(),
    ),
  );
}

class ArchitectEngineApp extends StatelessWidget {
  const ArchitectEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp(
      title: 'Architect Engine',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: appState.themeMode,
      home: const MainScaffold(),
    );
  }
}
