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
