class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    this.visitRecordId,
    this.documentId,
    this.transferId,
    this.petId,
    this.petName,
    this.medicationId,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String status;
  final DateTime createdAt;
  final String? visitRecordId;
  final String? documentId;
  final String? transferId;
  final String? petId;
  final String? petName;
  final String? medicationId;

  bool get isUnread => status == 'unread';

  AppNotification copyWith({String? status}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      status: status ?? this.status,
      createdAt: createdAt,
      visitRecordId: visitRecordId,
      documentId: documentId,
      transferId: transferId,
      petId: petId,
      petName: petName,
      medicationId: medicationId,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'unread',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      visitRecordId: json['visit_record_id'] as String? ??
          data['visit_record_id'] as String?,
      documentId:
          json['document_id'] as String? ?? data['document_id'] as String?,
      transferId: data['transfer_id'] as String?,
      petId: json['pet_id'] as String?,
      petName: data['pet_name'] as String?,
      medicationId: data['medication_id'] as String?,
    );
  }
}
