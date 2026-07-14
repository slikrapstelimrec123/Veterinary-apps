class SaleAnnouncement {
  const SaleAnnouncement({
    required this.id,
    required this.ownerName,
    required this.phone,
    required this.breed,
    required this.puppyName,
    required this.gender,
    required this.birthDate,
    required this.price,
    this.photoUrl,
    this.color,
    this.hasVaccinations,
    this.hasPedigree,
    this.hasChip,
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
  final String puppyName;
  final String gender;
  final DateTime birthDate;
  final int price;
  final String? photoUrl;
  final String? color;
  final bool? hasVaccinations;
  final bool? hasPedigree;
  final bool? hasChip;
  final String? notes;
  final String? location;
  final DateTime createdAt;
  final bool isActive;
  final String? ownerId;
  final String? petId;

  factory SaleAnnouncement.fromJson(Map<String, dynamic> json) {
    return SaleAnnouncement(
      id: json['id'] as String,
      ownerName: json['contact_name'] as String,
      phone: json['contact_phone'] as String,
      breed: json['breed'] as String,
      puppyName: json['pet_name'] as String,
      gender: (json['gender'] as String?) ?? 'unknown',
      birthDate: DateTime.tryParse(json['birth_date'] as String? ?? '') ??
          DateTime.now(),
      price: (json['price_amount'] as num?)?.toInt() ?? 0,
      photoUrl: json['photo_url'] as String?,
      color: json['color'] as String?,
      hasVaccinations: json['has_vaccinations'] as bool?,
      hasPedigree: json['has_pedigree'] as bool?,
      hasChip: json['has_chip'] as bool?,
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
        'announcement_type': 'sale',
        'contact_name': ownerName,
        'contact_phone': phone,
        'breed': breed,
        'pet_name': puppyName,
        'gender': gender,
        'birth_date': birthDate.toIso8601String().split('T').first,
        'price_amount': price,
        'photo_url': photoUrl,
        'color': color,
        'has_vaccinations': hasVaccinations,
        'has_pedigree': hasPedigree,
        'has_chip': hasChip,
        'description': notes,
        'city': location,
      };

  String get genderLabel => gender == 'male' ? 'Самець' : 'Самка';
  String get priceLabel => '$price грн';
  int get ageInWeeks {
    final now = DateTime.now();
    return now.difference(birthDate).inDays ~/ 7;
  }

  String get ageLabel {
    final weeks = ageInWeeks;
    if (weeks < 4) return '$weeks тиж.';
    final months = weeks ~/ 4;
    if (months == 1) return '1 міс.';
    if (months < 5) return '$months міс.';
    return '$months міс.';
  }
}
