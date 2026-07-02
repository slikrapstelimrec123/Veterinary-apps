class PetHealthEvent {
  const PetHealthEvent({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.dateDone,
    this.nextDueDate,
    this.clinicName,
    this.doctorName,
    this.notes,
  });

  final String id;
  final String petId;
  final String type;
  final String title;
  final DateTime dateDone;
  final DateTime? nextDueDate;
  final String? clinicName;
  final String? doctorName;
  final String? notes;

  factory PetHealthEvent.fromJson(Map<String, dynamic> json) {
    return PetHealthEvent(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      type: json['type'] as String? ?? 'other',
      title: json['title'] as String? ?? '',
      dateDone: DateTime.tryParse(json['date_done'] as String? ?? '') ?? DateTime.now(),
      nextDueDate: DateTime.tryParse(json['next_due_date'] as String? ?? ''),
      clinicName: json['clinic_name'] as String?,
      doctorName: json['doctor_name'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson(String ownerId) {
    return {
      'pet_id': petId,
      'owner_id': ownerId,
      'type': type,
      'title': title,
      'date_done': dateDone.toIso8601String().split('T').first,
      'next_due_date': nextDueDate?.toIso8601String().split('T').first,
      'clinic_name': clinicName,
      'doctor_name': doctorName,
      'notes': notes,
    };
  }
}

class PetDocument {
  const PetDocument({
    required this.id,
    required this.petId,
    required this.title,
    required this.documentType,
    this.fileName,
    this.description,
    this.documentDate,
  });

  final String id;
  final String petId;
  final String title;
  final String documentType;
  final String? fileName;
  final String? description;
  final DateTime? documentDate;

  factory PetDocument.fromJson(Map<String, dynamic> json) {
    return PetDocument(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      title: json['title'] as String? ?? '',
      documentType: json['document_type'] as String? ?? 'other',
      fileName: json['file_name'] as String?,
      description: json['description'] as String?,
      documentDate: DateTime.tryParse(json['document_date'] as String? ?? ''),
    );
  }
}

class PetReminder {
  const PetReminder({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.dueDate,
    required this.status,
    this.description,
    this.repeatRule,
  });

  final String id;
  final String petId;
  final String type;
  final String title;
  final DateTime dueDate;
  final String status;
  final String? description;
  final String? repeatRule;

  factory PetReminder.fromJson(Map<String, dynamic> json) {
    return PetReminder(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      type: json['type'] as String? ?? 'custom',
      title: json['title'] as String? ?? '',
      dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'upcoming',
      description: json['description'] as String?,
      repeatRule: json['repeat_rule'] as String?,
    );
  }
}

class PetPublicProfile {
  const PetPublicProfile({
    required this.id,
    required this.petId,
    required this.publicSlug,
    required this.isEnabled,
    this.publicNote,
  });

  final String id;
  final String petId;
  final String publicSlug;
  final bool isEnabled;
  final String? publicNote;

  factory PetPublicProfile.fromJson(Map<String, dynamic> json) {
    return PetPublicProfile(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      publicSlug: json['public_slug'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? false,
      publicNote: json['public_note'] as String?,
    );
  }
}
