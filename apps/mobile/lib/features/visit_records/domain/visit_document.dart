class VisitDocument {
  const VisitDocument({
    required this.id,
    required this.visitRecordId,
    required this.petId,
    required this.title,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String visitRecordId;
  final String petId;
  final String title;
  final String type;
  final DateTime createdAt;

  factory VisitDocument.fromJson(Map<String, dynamic> json) {
    return VisitDocument(
      id: json['id'] as String,
      visitRecordId: json['visit_record_id'] as String,
      petId: json['pet_id'] as String,
      title: json['title'] as String? ?? 'Medical document',
      type: json['document_type'] as String? ?? 'other',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

