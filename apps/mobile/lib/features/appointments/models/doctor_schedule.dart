class DoctorSchedule {
  const DoctorSchedule({
    required this.id,
    required this.clinicId,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.slotDurationMinutes = 30,
    this.isActive = true,
  });

  final String id;
  final String clinicId;
  final String doctorId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? breakStartTime;
  final String? breakEndTime;
  final int slotDurationMinutes;
  final bool isActive;

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorSchedule(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
      startTime: _shortTime(json['start_time'] as String? ?? '09:00'),
      endTime: _shortTime(json['end_time'] as String? ?? '18:00'),
      breakStartTime: json['break_start_time'] == null ? null : _shortTime(json['break_start_time'] as String),
      breakEndTime: json['break_end_time'] == null ? null : _shortTime(json['break_end_time'] as String),
      slotDurationMinutes: (json['slot_duration_minutes'] as num?)?.toInt() ?? 30,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

String _shortTime(String value) => value.length >= 5 ? value.substring(0, 5) : value;
