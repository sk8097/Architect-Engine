import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => notifProvider.markAllAsRead(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: () => notifProvider.clearAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Test buttons bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifProvider.addNotification('payment', 'Payment Received', '₹25,000 credited for 3BHK project.'),
                    child: const Text('💰 Payment', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifProvider.addNotification('design', 'Design Ready', 'Floor plan revision R03 prepared.'),
                    child: const Text('📐 Design', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifProvider.addNotification('alert', 'Sanction Alert', 'Municipality fee due tomorrow.'),
                    child: const Text('⚠️ Alert', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: notifProvider.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🔕', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('No notifications', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notifProvider.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifProvider.notifications[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border(
                            left: BorderSide(
                              color: notif.isRead ? Colors.transparent : AppColors.darkPrimary,
                              width: 4,
                            ),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => notifProvider.markAsRead(notif.id),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.darkIconBg,
                            child: Text(
                              notif.type == 'payment'
                                  ? '💰'
                                  : notif.type == 'design'
                                      ? '📐'
                                      : notif.type == 'alert'
                                          ? '⚠️'
                                          : '🔔',
                            ),
                          ),
                          title: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            notif.message,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Text(
                            '${notif.time.hour}:${notif.time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
