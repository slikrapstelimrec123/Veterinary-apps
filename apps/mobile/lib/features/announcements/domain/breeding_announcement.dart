class BreedingAnnouncement {
  const BreedingAnnouncement({
    required this.id,
    required this.ownerName,
    required this.phone,
    required this.breed,
    required this.myDogName,
    required this.myDogGender,
    required this.myDogAge,
    this.myDogPhotoUrl,
    this.photoStoragePath,
    this.petAvatarUrl,
    this.petAvatarStoragePath,
    this.desiredBreed,
    this.conditions,
    this.notes,
    this.location,
    required this.createdAt,
    this.isActive = true,
    this.ownerId,
    this.petId,
  });

  final String id;
  final String ownerName;
  final String phone;
  final String breed;
  final String myDogName;
  final String myDogGender;
  final int myDogAge;
  final String? myDogPhotoUrl;
  final String? photoStoragePath;
  final String? petAvatarUrl;
  final String? petAvatarStoragePath;
  final String? desiredBreed;
  final String? conditions;
  final String? notes;
  final String? location;
  final DateTime createdAt;
  final bool isActive;
  final String? ownerId;
  final String? petId;

  factory BreedingAnnouncement.fromJson(Map<String, dynamic> json) {
    return BreedingAnnouncement(
      id: json['id'] as String,
      ownerName: json['contact_name'] as String,
      phone: json['contact_phone'] as String,
      breed: json['breed'] as String,
      myDogName: json['pet_name'] as String,
      myDogGender: _normalizedGender(json['gender']),
      myDogAge: (json['age_years'] as num?)?.toInt() ?? 0,
      myDogPhotoUrl:
          json['cover_photo_url'] as String? ?? json['photo_url'] as String?,
      photoStoragePath: json['cover_photo_storage_path'] as String? ??
          json['photo_storage_path'] as String?,
      petAvatarUrl:
          json['pet_avatar_url'] as String? ?? json['photo_url'] as String?,
      petAvatarStoragePath: json['pet_avatar_storage_path'] as String? ??
          json['photo_storage_path'] as String?,
      desiredBreed: json['desired_breed'] as String?,
      conditions: json['conditions'] as String?,
      notes: json['description'] as String?,
      location: json['city'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['status'] == 'active',
      ownerId: json['owner_id'] as String?,
      petId: json['pet_id'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({required String currentOwnerId}) => {
        'owner_id': currentOwnerId,
        'pet_id': petId,
        'announcement_type': 'breeding',
        'contact_name': ownerName,
        'contact_phone': phone,
        'breed': breed,
        'pet_name': myDogName,
        'gender': myDogGender,
        'age_years': myDogAge,
        'cover_photo_url': myDogPhotoUrl,
        'cover_photo_storage_path': photoStoragePath,
        'desired_breed': desiredBreed,
        'conditions': conditions,
        'description': notes,
        'city': location,
      };

  Map<String, dynamic> toUpdateJson() => {
        'breed': breed,
        'pet_name': myDogName,
        'cover_photo_url': myDogPhotoUrl,
        'cover_photo_storage_path': photoStoragePath,
        'conditions': conditions,
        'description': notes,
        'city': location,
        'contact_phone': phone,
      };

  String get genderLabel => switch (myDogGender) {
        'male' => 'Самець',
        'female' => 'Самка',
        _ => 'Стать не вказана',
      };
  String get ageLabel {
    if (myDogAge == 1) return '1 рік';
    if (myDogAge < 5) return '$myDogAge роки';
    return '$myDogAge років';
  }

  static String _normalizedGender(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'male' || 'm' || 'самець' || 'самец' => 'male',
      'female' || 'f' || 'самка' => 'female',
      _ => 'unknown',
    };
  }
}
