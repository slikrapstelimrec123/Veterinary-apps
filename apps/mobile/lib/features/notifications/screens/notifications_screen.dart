import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../pet_transfer/data/pet_transfer_repository.dart';
import '../../pet_transfer/domain/pet_transfer.dart';
import '../../pet_transfer/screens/incoming_transfers_screen.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../appointments/screens/appointment_details_screen.dart';
import '../../visit_records/screens/visit_record_details_screen.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final repository = NotificationRepository();
  final _transferRepo = PetTransferRepository();
  late final Future<List<PetTransfer>> _transfersFuture =
      _transferRepo.getIncomingTransfers();
  late Future<List<AppNotification>> future = repository.getNotifications();

  void refresh() {
    setState(() => future = repository.getNotifications());
  }

  Future<void> markAllAsRead() async {
    await repository.markAllAsRead();
    refresh();
  }

  Future<void> openNotification(AppNotification notification) async {
    await repository.markAsRead(notification.id);
    if (!mounted) return;

    if (notification.appointmentId != null) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(
              appointmentId: notification.appointmentId!)));
    } else if (notification.visitRecordId != null) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              VisitRecordDetailsScreen(recordId: notification.visitRecordId!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Пов’язаний екран буде додано пізніше.')));
    }

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotification>>(
      future: future,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unread = notifications.where((item) => item.isUnread).toList();
        final read = notifications.where((item) => !item.isUnread).toList();

        return AppScaffold(
          title: 'Сповіщення',
          subtitle: 'Важливі оновлення щодо записів, лікування та документів.',
          actions: [
            if (unread.isNotEmpty)
              IconButton(
                  onPressed: markAllAsRead,
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Позначити всі як прочитані'),
          ],
          children: [
            FutureBuilder<List<PetTransfer>>(
              future: _transfersFuture,
              builder: (context, ts) {
                final transfers = ts.data ?? [];
                if (transfers.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const IncomingTransfersScreen())),
                  child: Card(
                    color: AppTheme.primary.withOpacity(0.08),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.pets, color: AppTheme.primary, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '\u0423 \u0432\u0430\u0441 \u0454 \u0437\u0430\u043f\u0438\u0442(\u0438) \u043d\u0430 \u043f\u0435\u0440\u0435\u0434\u0430\u0447\u0443 \u0442\u0432\u0430\u0440\u0438\u043d\u0438',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити сповіщення.',
                  onRetry: refresh)
            else if (notifications.isEmpty)
              const EmptyState(
                title: 'Сповіщень поки немає',
                message: 'Важливі оновлення з’являться тут.',
                icon: Icons.notifications_none_outlined,
              )
            else ...[
              if (unread.isNotEmpty) ...[
                Text('Непрочитані',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...unread.map((notification) => _NotificationTile(
                    notification: notification,
                    onTap: () => openNotification(notification))),
                const SizedBox(height: 16),
              ],
              if (read.isNotEmpty) ...[
                Text('Прочитані',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...read.map((notification) => _NotificationTile(
                    notification: notification,
                    onTap: () => openNotification(notification))),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(notificationIcon(notification.type),
              color: notification.isUnread
                  ? Theme.of(context).colorScheme.primary
                  : null),
          title: Text(notification.title,
              style: TextStyle(
                  fontWeight: notification.isUnread
                      ? FontWeight.w800
                      : FontWeight.w500)),
          subtitle: Text(
              '${notification.body}\n${dateLabel(notification.createdAt)}'),
          isThreeLine: true,
          trailing: notification.isUnread
              ? const Icon(Icons.circle, size: 10)
              : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

IconData notificationIcon(String type) {
  if (type.contains('appointment')) return Icons.event_available_outlined;
  if (type.contains('visit') || type.contains('document')) {
    return Icons.medical_information_outlined;
  }
  if (type.contains('review')) return Icons.star_border;
  return Icons.notifications_none_outlined;
}

String dateLabel(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
