class PetAchievement {
  const PetAchievement({
    required this.id,
    required this.petId,
    required this.title,
    required this.eventDate,
    this.eventType,
    this.location,
    this.result,
    this.awardTitle,
    this.awardImageUrl,
    this.eventPhotoUrl,
    this.awardImagePath,
    this.eventPhotoPath,
    this.notes,
    this.endDate,
    this.createdAt,
  });

  final String id;
  final String petId;
  final String title;
  final DateTime eventDate;
  final DateTime? endDate;
  final String? eventType;
  final String? location;
  final String? result;
  final String? awardTitle;
  final String? awardImageUrl;
  final String? eventPhotoUrl;
  final String? awardImagePath;
  final String? eventPhotoPath;
  final String? notes;
  final DateTime? createdAt;

  String get eventTypeLabel => switch (eventType) {
        'competition' => 'Змагання',
        'exhibition' => 'Виставка',
        'training' => 'Тренування',
        'certification' => 'Сертифікація',
        _ => eventType ?? 'Подія',
      };

  factory PetAchievement.fromJson(Map<String, dynamic> json) {
    return PetAchievement(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      title: json['title'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      eventType: json['event_type'] as String?,
      location: json['location'] as String?,
      result: json['result'] as String?,
      awardTitle: json['award_title'] as String?,
      awardImageUrl: json['award_image_url'] as String?,
      eventPhotoUrl: json['event_photo_url'] as String?,
      awardImagePath: json['award_image_path'] as String?,
      eventPhotoPath: json['event_photo_path'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'pet_id': petId,
        'title': title,
        'event_date': eventDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'event_type': eventType,
        'location': location,
        'result': result,
        'award_title': awardTitle,
        'award_image_url': awardImageUrl,
        'event_photo_url': eventPhotoUrl,
        'award_image_path': awardImagePath,
        'event_photo_path': eventPhotoPath,
        'notes': notes,
      };
}
