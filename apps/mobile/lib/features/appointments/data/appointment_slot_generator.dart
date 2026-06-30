import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/doctor_schedule.dart';
import '../../../shared/utils/iterable_extensions.dart';

class AppointmentSlotGenerator {
  List<AppointmentSlot> generate({
    required DateTime date,
    required String doctorId,
    required int serviceDurationMinutes,
    required List<DoctorSchedule> schedules,
    required List<Appointment> appointments,
  }) {
    final schedule = schedules.where((item) => item.doctorId == doctorId && item.dayOfWeek == date.weekday && item.isActive).firstOrNull;

    if (schedule == null) {
      return [];
    }

    final slotMinutes = serviceDurationMinutes > 0 ? serviceDurationMinutes : schedule.slotDurationMinutes;
    final now = DateTime.now();
    final dayStart = _onDate(date, schedule.startTime);
    final dayEnd = _onDate(date, schedule.endTime);
    final breakStart = schedule.breakStartTime == null ? null : _onDate(date, schedule.breakStartTime!);
    final breakEnd = schedule.breakEndTime == null ? null : _onDate(date, schedule.breakEndTime!);
    final doctorAppointments = appointments.where((appointment) {
      return appointment.doctorId == doctorId &&
          _sameDay(appointment.appointmentDate, date) &&
          !appointment.status.startsWith('cancelled');
    }).toList();
    final slots = <AppointmentSlot>[];

    for (var start = dayStart; start.add(Duration(minutes: slotMinutes)).isAtSameMomentAs(dayEnd) || start.add(Duration(minutes: slotMinutes)).isBefore(dayEnd); start = start.add(Duration(minutes: slotMinutes))) {
      final end = start.add(Duration(minutes: slotMinutes));
      final isPast = start.isBefore(now);
      final overlapsBreak = breakStart != null && breakEnd != null && start.isBefore(breakEnd) && end.isAfter(breakStart);
      final overlapsAppointment = doctorAppointments.any((appointment) {
        final bookedStart = _onDate(date, appointment.startTime);
        final bookedEnd = _onDate(date, appointment.endTime);
        return start.isBefore(bookedEnd) && end.isAfter(bookedStart);
      });

      if (!isPast && !overlapsBreak && !overlapsAppointment) {
        slots.add(AppointmentSlot(doctorId: doctorId, date: date, startTime: _formatTime(start), endTime: _formatTime(end)));
      }
    }

    return slots;
  }

  DateTime _onDate(DateTime date, String time) {
    final parts = time.split(':').map(int.parse).toList();
    return DateTime(date.year, date.month, date.day, parts[0], parts.length > 1 ? parts[1] : 0);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _sameDay(DateTime left, DateTime right) => left.year == right.year && left.month == right.month && left.day == right.day;
}
