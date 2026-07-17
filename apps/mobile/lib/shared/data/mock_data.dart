import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/domain/notification_preferences.dart';
import '../../features/pets/domain/pet.dart';
import '../../features/visit_records/domain/visit_document.dart';
import '../../features/visit_records/domain/visit_record.dart';

class MockData {
  static NotificationPreferences notificationPreferences =
      const NotificationPreferences();

  static final pets = <Pet>[];
  static final notifications = <AppNotification>[];
  static final visitRecords = <VisitRecord>[];
  static final documents = <VisitDocument>[];
}
