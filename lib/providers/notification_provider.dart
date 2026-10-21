import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('ae_notifs') ?? [];
    if (rawList.isEmpty) {
      // Add initial welcome notification
      _notifications = [
        AppNotification(
          id: 'welcome_1',
          type: 'info',
          title: 'Welcome to Architect Engine!',
          message: 'Start by creating your first architectural project or exploring 168 calculation tools.',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        )
      ];
    } else {
      _notifications = rawList.map((e) => AppNotification.fromMap(json.decode(e))).toList();
    }
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _notifications.map((e) => json.encode(e.toMap())).toList();
    await prefs.setStringList('ae_notifs', rawList);
  }

  Future<void> addNotification(String type, String title, String message) async {
    final newNotif = AppNotification(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      message: message,
      time: DateTime.now(),
      isRead: false,
    );
    _notifications.insert(0, newNotif);
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _saveNotifications();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveNotifications();
  }
}
