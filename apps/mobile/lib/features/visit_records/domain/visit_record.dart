class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.petId,
    required this.visitDate,
    this.clinicName,
    this.doctorName,
    this.reason,
    this.diagnosis,
    this.treatmentNotes,
    this.recommendations,
    this.followUpAt,
    this.documentCount = 0,
  });

  final String id;
  final String petId;
  final DateTime visitDate;
  final String? clinicName;
  final String? doctorName;
  final String? reason;
  final String? diagnosis;
  final String? treatmentNotes;
  final String? recommendations;
  final DateTime? followUpAt;
  final int documentCount;

  factory VisitRecord.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinics'];
    final doctor = json['doctors'];

    return VisitRecord(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      visitDate: DateTime.tryParse(json['visit_date'] as String? ?? '') ?? DateTime.now(),
      clinicName: clinic is Map<String, dynamic> ? clinic['name'] as String? : null,
      doctorName: doctor is Map<String, dynamic> ? doctor['full_name'] as String? : null,
      reason: json['reason'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatmentNotes: json['treatment_notes'] as String?,
      recommendations: json['recommendations'] as String?,
      followUpAt: DateTime.tryParse(json['follow_up_at'] as String? ?? ''),
    );
  }
}

