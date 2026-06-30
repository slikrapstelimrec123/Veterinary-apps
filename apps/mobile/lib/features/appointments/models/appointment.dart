class Appointment {
  const Appointment({
    required this.id,
    required this.petId,
    required this.petName,
    required this.clinicId,
    required this.clinicName,
    required this.serviceId,
    required this.serviceName,
    this.doctorId,
    this.doctorName,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.ownerNote,
    this.clinicNote,
    this.cancellationReason,
  });

  final String id;
  final String petId;
  final String petName;
  final String clinicId;
  final String clinicName;
  final String serviceId;
  final String serviceName;
  final String? doctorId;
  final String? doctorName;
  final DateTime appointmentDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? ownerNote;
  final String? clinicNote;
  final String? cancellationReason;

  DateTime get startsAt {
    final parts = startTime.split(':').map(int.parse).toList();
    return DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, parts[0], parts.length > 1 ? parts[1] : 0);
  }

  bool get canOwnerCancel => status == 'pending' || status == 'confirmed';

  String get statusLabel {
    return switch (status) {
      'pending' => 'Очікує',
      'confirmed' => 'Підтверджено',
      'completed' => 'Завершено',
      'cancelled_by_owner' => 'Скасовано вами',
      'cancelled_by_clinic' => 'Скасовано клінікою',
      'no_show' => 'Не прийшли',
      _ => status,
    };
  }

  Appointment copyWith({
    String? status,
    String? cancellationReason,
    String? clinicNote,
    String? doctorId,
    String? doctorName,
  }) {
    return Appointment(
      id: id,
      petId: petId,
      petName: petName,
      clinicId: clinicId,
      clinicName: clinicName,
      serviceId: serviceId,
      serviceName: serviceName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      appointmentDate: appointmentDate,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      ownerNote: ownerNote,
      clinicNote: clinicNote ?? this.clinicNote,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final pet = json['pets'];
    final clinic = json['clinics'];
    final service = json['services'];
    final doctor = json['doctors'];

    return Appointment(
      id: json['id'] as String,
      petId: json['pet_id'] as String? ?? '',
      petName: pet is Map<String, dynamic> ? pet['name'] as String? ?? '' : json['pet_name'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',
      clinicName: clinic is Map<String, dynamic> ? clinic['name'] as String? ?? '' : json['clinic_name'] as String? ?? '',
      serviceId: json['service_id'] as String? ?? '',
      serviceName: service is Map<String, dynamic> ? service['name'] as String? ?? '' : json['service_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String?,
      doctorName: doctor is Map<String, dynamic> ? doctor['full_name'] as String? : json['doctor_name'] as String?,
      appointmentDate: DateTime.tryParse(json['appointment_date'] as String? ?? '') ?? DateTime.now(),
      startTime: _shortTime(json['start_time'] as String? ?? '09:00'),
      endTime: _shortTime(json['end_time'] as String? ?? '09:30'),
      status: json['status'] as String? ?? 'pending',
      ownerNote: json['owner_note'] as String? ?? json['owner_comment'] as String?,
      clinicNote: json['clinic_note'] as String? ?? json['clinic_comment'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({required String ownerId}) {
    final date = appointmentDate.toIso8601String().split('T').first;

    return {
      'pet_id': petId,
      'clinic_id': clinicId,
      'service_id': serviceId,
      'doctor_id': doctorId,
      'owner_id': ownerId,
      'appointment_date': date,
      'start_time': startTime,
      'end_time': endTime,
      'starts_at': '${date}T$startTime:00',
      'ends_at': '${date}T$endTime:00',
      'status': status,
      'owner_note': ownerNote,
      'owner_comment': ownerNote,
    };
  }
}

String _shortTime(String value) => value.length >= 5 ? value.substring(0, 5) : value;
