import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../pet_transfer/screens/incoming_transfers_screen.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../achievements/screens/achievements_screen.dart';
import '../../announcements/screens/announcements_screen.dart';
import '../../feeding/screens/feeding_screen.dart';
import '../../pets/screens/pet_profile_screen.dart';
import '../../visit_records/screens/documents_screen.dart';
import '../../visit_records/screens/visit_record_details_screen.dart';
import '../../medications/screens/medications_screen.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final repository = NotificationRepository();
  late Future<List<AppNotification>> future;

  @override
  void initState() {
    super.initState();
    _reloadFutures();
  }

  void _reloadFutures() {
    future = repository.getNotifications();
  }

  void refresh() {
    setState(_reloadFutures);
  }

  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
      if (mounted) refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Не вдалося позначити сповіщення як прочитані.'),
      ));
    }
  }

  Future<void> openNotification(AppNotification notification) async {
    try {
      if (notification.isUnread) {
        await repository.markAsRead(notification.id);
      }
      if (!mounted) return;
      refresh();
      await _openDestination(notification);
      if (mounted) refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Не вдалося відкрити сповіщення. Спробуйте ще раз.'),
      ));
    }
  }

  Future<void> _openDestination(AppNotification notification) async {
    final type = notification.type.toLowerCase();
    Widget? destination;

    if (type.contains('transfer')) {
      destination = const IncomingTransfersScreen();
    } else if (notification.visitRecordId != null) {
      destination =
          VisitRecordDetailsScreen(recordId: notification.visitRecordId!);
    } else if (type.contains('medication') && notification.petId != null) {
      destination = MedicationsScreen(
        petId: notification.petId!,
        petName: notification.petName ?? 'Тварина',
      );
    } else if (type.contains('document') && notification.petId != null) {
      destination = DocumentsScreen(
        petId: notification.petId!,
        petName: notification.petName ?? 'Тварина',
      );
    } else if ((type.contains('feeding') || type.contains('food')) &&
        notification.petId != null) {
      destination = FeedingScreen(
        petId: notification.petId!,
        petName: notification.petName ?? 'Тварина',
      );
    } else if ((type.contains('achievement') || type.contains('event')) &&
        notification.petId != null) {
      destination = AchievementsScreen(
        petId: notification.petId!,
        petName: notification.petName ?? 'Тварина',
      );
    } else if (type.contains('announcement')) {
      destination = const AnnouncementsScreen();
    } else if (notification.petId != null) {
      destination = PetProfileScreen(petId: notification.petId!);
    }

    if (destination != null) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => destination!));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
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
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити сповіщення.',
                  onRetry: refresh)
            else ...[
              if (notifications.isEmpty)
                const EmptyState(
                  title: 'Сповіщень поки немає',
                  message: 'Важливі оновлення з’являться тут.',
                  icon: Icons.notifications_none_outlined,
                ),
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
  if (type.contains('transfer')) return Icons.pets_outlined;
  if (type.contains('visit') || type.contains('document')) {
    return Icons.medical_information_outlined;
  }
  if (type.contains('medication')) return Icons.medication_outlined;
  return Icons.notifications_none_outlined;
}

String dateLabel(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
