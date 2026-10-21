import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _currentLanguage = 'en';
  List<int> _favoriteToolIds = [];
  String _userName = 'Guest User';
  String _userEmail = '';
  String _userPhone = '';
  String _storageType = 'local';
  bool _gdriveConnected = false;
  String _gdriveEmail = '';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currentLanguage => _currentLanguage;
  List<int> get favoriteToolIds => _favoriteToolIds;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get storageType => _storageType;
  bool get gdriveConnected => _gdriveConnected;
  String get gdriveEmail => _gdriveEmail;

  AppStateProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final savedTheme = prefs.getString('ae_theme') ?? 'dark';
    _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

    // Language
    _currentLanguage = prefs.getString('ae_lang') ?? 'en';

    // Favorites
    final favStringList = prefs.getStringList('ae_tool_favs') ?? [];
    _favoriteToolIds = favStringList.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();

    // Profile
    _userName = prefs.getString('ae_name') ?? 'Guest User';
    _userEmail = prefs.getString('ae_email') ?? '';
    _userPhone = prefs.getString('ae_phone') ?? '';

    // Storage
    _storageType = prefs.getString('ae_storage') ?? 'local';
    _gdriveConnected = prefs.getBool('ae_gdrive') ?? false;
    _gdriveEmail = prefs.getString('ae_gdrive_email') ?? '';

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_theme', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_lang', langCode);
  }

  Future<void> toggleFavorite(int toolId) async {
    if (_favoriteToolIds.contains(toolId)) {
      _favoriteToolIds.remove(toolId);
    } else {
      _favoriteToolIds.add(toolId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ae_tool_favs', _favoriteToolIds.map((e) => e.toString()).toList());
  }

  bool isFavorite(int toolId) => _favoriteToolIds.contains(toolId);

  Future<void> updateProfile({required String name, required String email, required String phone}) async {
    _userName = name;
    _userEmail = email;
    _userPhone = phone;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_name', name);
    await prefs.setString('ae_email', email);
    await prefs.setString('ae_phone', phone);
  }

  Future<void> setStorageType(String type) async {
    _storageType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ae_storage', type);
  }

  Future<void> connectGDrive(String email) async {
    _gdriveConnected = true;
    _gdriveEmail = email;
    _storageType = 'gdrive';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ae_gdrive', true);
    await prefs.setString('ae_gdrive_email', email);
    await prefs.setString('ae_storage', 'gdrive');
  }

  Future<void> disconnectGDrive() async {
    _gdriveConnected = false;
    _gdriveEmail = '';
    _storageType = 'local';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ae_gdrive', false);
    await prefs.remove('ae_gdrive_email');
    await prefs.setString('ae_storage', 'local');
  }
}
