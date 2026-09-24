import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final provider = context.read<NotificationProvider>();

    try {
      await provider.fetchNotifications();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Učitavanje notifikacija nije uspjelo: $error')),
      );
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) {
      return;
    }

    final provider = context.read<NotificationProvider>();

    try {
      await provider.markAsRead(notification.id);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Označavanje notifikacije nije uspjelo: $error'),
        ),
      );
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'product_activated':
        return Icons.shopping_bag_outlined;

      case 'orderstatuschanged':
        return Icons.local_shipping_outlined;

      case 'reservationstatuschanged':
        return Icons.calendar_month_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'product_activated':
        return Colors.green;

      case 'orderstatuschanged':
        return Colors.orange;

      case 'reservationstatuschanged':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy. HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikacije')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.notifications_none, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Nemate notifikacija.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];

                return Card(
                  color: notification.isRead
                      ? null
                      : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _markAsRead(notification),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: _getIconColor(
                              notification.type,
                            ).withValues(alpha: 0.15),
                            child: Icon(
                              _getIcon(notification.type),
                              color: _getIconColor(notification.type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: notification.isRead
                                              ? FontWeight.w500
                                              : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(notification.message),
                                const SizedBox(height: 8),
                                Text(
                                  dateFormat.format(
                                    notification.createdAt.toLocal(),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
