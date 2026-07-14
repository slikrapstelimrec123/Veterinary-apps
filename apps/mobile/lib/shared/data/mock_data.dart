import '../../features/appointments/models/appointment.dart';
import '../../features/appointments/models/doctor_schedule.dart';
import '../../features/clinics/models/clinic.dart';
import '../../features/clinics/models/doctor.dart';
import '../../features/clinics/models/service.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/domain/notification_preferences.dart';
import '../../features/pets/domain/pet.dart';
import '../../features/reviews/domain/review.dart';
import '../../features/visit_records/domain/visit_document.dart';
import '../../features/visit_records/domain/visit_record.dart';

class MockData {
  static NotificationPreferences notificationPreferences =
      const NotificationPreferences();

  static final pets = <Pet>[];
  static const clinics = <Clinic>[];
  static const doctors = <Doctor>[];
  static const services = <ClinicService>[];
  static const doctorSchedules = <DoctorSchedule>[];
  static final appointments = <Appointment>[];
  static final notifications = <AppNotification>[];
  static final visitRecords = <VisitRecord>[];
  static final documents = <VisitDocument>[];
  static final reviews = <Review>[];
}
