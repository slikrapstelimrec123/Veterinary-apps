class Doctor {
  const Doctor({
    required this.id,
    required this.clinicId,
    required this.fullName,
    required this.specialization,
    required this.clinicName,
    this.bio,
    this.experienceYears,
    this.avatarUrl,
    this.defaultAppointmentDurationMinutes = 30,
    this.status = 'active',
    this.isPublic = true,
  });

  final String id;
  final String clinicId;
  final String fullName;
  final String specialization;
  final String clinicName;
  final String? bio;
  final int? experienceYears;
  final String? avatarUrl;
  final int defaultAppointmentDurationMinutes;
  final String status;
  final bool isPublic;

  bool get isBookable => status == 'active' && isPublic;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinics'];

    return Doctor(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? 'Veterinarian',
      clinicName: clinic is Map<String, dynamic> ? clinic['name'] as String? ?? '' : json['clinic_name'] as String? ?? '',
      bio: json['bio'] as String?,
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      avatarUrl: json['avatar_url'] as String?,
      defaultAppointmentDurationMinutes: (json['default_appointment_duration_minutes'] as num?)?.toInt() ?? 30,
      status: json['status'] as String? ?? 'draft',
      isPublic: json['is_public'] as bool? ?? false,
    );
  }
}
