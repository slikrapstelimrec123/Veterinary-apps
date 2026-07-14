class VisitDocument {
  const VisitDocument({
    required this.id,
    required this.visitRecordId,
    required this.petId,
    required this.title,
    required this.type,
    required this.createdAt,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.description,
    this.storageBucket = 'visit-documents',
    this.storagePath,
    this.isVisibleToOwner = true,
  });

  final String id;
  final String visitRecordId;
  final String petId;
  final String title;
  final String type;
  final DateTime createdAt;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? description;
  final String storageBucket;
  final String? storagePath;
  final bool isVisibleToOwner;

  String get fileSizeLabel {
    if (fileSize == null) {
      return 'Розмір недоступний';
    }

    final mb = fileSize! / (1024 * 1024);
    return mb >= 1
        ? '${mb.toStringAsFixed(1)} MB'
        : '${(fileSize! / 1024).toStringAsFixed(0)} KB';
  }

  factory VisitDocument.fromJson(Map<String, dynamic> json) {
    return VisitDocument(
      id: json['id'] as String,
      visitRecordId: json['visit_record_id'] as String,
      petId: json['pet_id'] as String,
      title: json['title'] as String? ?? 'Медичний документ',
      type: json['document_type'] as String? ?? 'other',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      fileName: json['file_name'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      description: json['description'] as String?,
      storageBucket: json['storage_bucket'] as String? ?? 'visit-documents',
      storagePath: json['storage_path'] as String?,
      isVisibleToOwner: json['is_visible_to_owner'] as bool? ?? true,
    );
  }
}
