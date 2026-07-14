import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../domain/app_notification.dart';
import '../domain/notification_preferences.dart';

class NotificationRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<AppNotification>> getNotifications() async {
    if (_useMockData) {
      final rows = [...MockData.notifications];
      rows.sort((left, right) => right.createdAt.compareTo(left.createdAt));
      return rows;
    }

    final rows = await _client
        .from('notifications')
        .select('*')
        .neq('status', 'archived')
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<int> getUnreadCount() async {
    if (_useMockData) {
      return MockData.notifications
          .where((notification) => notification.isUnread)
          .length;
    }

    final rows =
        await _client.from('notifications').select('id').eq('status', 'unread');
    return (rows as List<dynamic>).length;
  }

  Future<void> markAsRead(String id) async {
    if (_useMockData) {
      final index = MockData.notifications
          .indexWhere((notification) => notification.id == id);
      if (index >= 0) {
        MockData.notifications[index] =
            MockData.notifications[index].copyWith(status: 'read');
      }
      return;
    }

    await _client
        .rpc('mark_notification_read', params: {'target_notification_id': id});
  }

  Future<void> markAllAsRead() async {
    if (_useMockData) {
      for (var index = 0; index < MockData.notifications.length; index++) {
        MockData.notifications[index] =
            MockData.notifications[index].copyWith(status: 'read');
      }
      return;
    }

    await _client.rpc('mark_all_notifications_read');
  }

  Future<NotificationPreferences> getPreferences() async {
    if (_useMockData) {
      return MockData.notificationPreferences;
    }

    final row = await _client.rpc('get_my_notification_preferences');
    return NotificationPreferences.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    if (_useMockData) {
      MockData.notificationPreferences = preferences;
      return;
    }

    await _client.rpc(
      'save_my_notification_preferences',
      params: {
        'p_in_app_enabled': preferences.inAppEnabled,
        'p_appointment_reminders_enabled':
            preferences.appointmentRemindersEnabled,
        'p_treatment_updates_enabled': preferences.treatmentUpdatesEnabled,
        'p_review_requests_enabled': preferences.reviewRequestsEnabled,
      },
    );
  }
}
