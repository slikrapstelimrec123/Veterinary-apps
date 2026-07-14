class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.petId,
    required this.visitDate,
    this.clinicId,
    this.doctorId,
    this.appointmentId,
    this.clinicName,
    this.doctorName,
    this.reason,
    this.symptoms,
    this.diagnosis,
    this.proceduresPerformed,
    this.treatmentNotes,
    this.prescribedMedications,
    this.recommendations,
    this.nextVisitRecommended = false,
    this.nextVisitDate,
    this.status = 'published',
    this.documentCount = 0,
  });

  final String id;
  final String petId;
  final DateTime visitDate;
  final String? clinicId;
  final String? doctorId;
  final String? appointmentId;
  final String? clinicName;
  final String? doctorName;
  final String? reason;
  final String? symptoms;
  final String? diagnosis;
  final String? proceduresPerformed;
  final String? treatmentNotes;
  final String? prescribedMedications;
  final String? recommendations;
  final bool nextVisitRecommended;
  final DateTime? nextVisitDate;
  final String status;
  final int documentCount;

  factory VisitRecord.fromJson(Map<String, dynamic> json) {
    final clinic = json['clinics'];
    final doctor = json['doctors'];

    return VisitRecord(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      clinicId: json['clinic_id'] as String?,
      doctorId: json['doctor_id'] as String?,
      appointmentId: json['appointment_id'] as String?,
      visitDate: DateTime.tryParse(json['visit_date'] as String? ?? '') ??
          DateTime.now(),
      clinicName:
          clinic is Map<String, dynamic> ? clinic['name'] as String? : null,
      doctorName: doctor is Map<String, dynamic>
          ? doctor['full_name'] as String?
          : null,
      reason: json['reason'] as String?,
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      proceduresPerformed: null,
      treatmentNotes: json['treatment'] as String?,
      prescribedMedications: json['medications_given'] as String?,
      recommendations: json['recommendations'] as String?,
      nextVisitRecommended: json['next_visit_date'] != null,
      nextVisitDate:
          DateTime.tryParse(json['next_visit_date'] as String? ?? ''),
      status: json['status'] as String? ?? 'self_reported',
      documentCount: (json['document_count'] as num?)?.toInt() ?? 0,
    );
  }
}
