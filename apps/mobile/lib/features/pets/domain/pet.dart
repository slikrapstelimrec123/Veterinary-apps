class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.birthDate,
    this.weightKg,
    this.color,
    this.microchipNumber,
    this.avatarUrl,
    this.notes,
    this.sterilized,
    this.allergies,
    this.chronicConditions,
    this.ownerContactName,
    this.ownerContactPhone,
    this.ownerContactEmail,
    this.emergencyContact,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final DateTime? birthDate;
  final double? weightKg;
  final String? color;
  final String? microchipNumber;
  final String? avatarUrl;
  final String? notes;
  final bool? sterilized;
  final String? allergies;
  final String? chronicConditions;
  final String? ownerContactName;
  final String? ownerContactPhone;
  final String? ownerContactEmail;
  final String? emergencyContact;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get speciesLabel {
    return switch (species.toLowerCase()) {
      'dog' => 'Собака',
      'cat' => 'Кіт',
      'rabbit' => 'Кролик',
      'bird' => 'Птах',
      'rodent' => 'Гризун',
      'reptile' => 'Рептилія',
      'other' => 'Інше',
      '' => 'Вид невідомий',
      _ => species,
    };
  }

  String get sexLabel {
    return switch (sex?.toLowerCase()) {
      'male' => 'Самець',
      'female' => 'Самка',
      'unknown' => 'Не вказано',
      null => 'Не вказано',
      _ => sex!,
    };
  }

  String get ageLabel {
    if (birthDate == null) {
      return 'Вік невідомий';
    }

    final now = DateTime.now();
    var years = now.year - birthDate!.year;
    if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }

    if (years <= 0) {
      final months = (now.year - birthDate!.year) * 12 + now.month - birthDate!.month;
      return months <= 1 ? 'Менше 1 місяця' : '$months міс.';
    }

    return years == 1 ? '1 рік' : '$years р.';
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'weight_kg': weightKg,
      'color': color,
      'microchip_number': microchipNumber,
      'avatar_url': avatarUrl,
      'notes': notes,
      'health_notes': notes,
      'photo_url': avatarUrl,
      'sterilized': sterilized,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'owner_contact_name': ownerContactName,
      'owner_contact_phone': ownerContactPhone,
      'owner_contact_email': ownerContactEmail,
      'emergency_contact': emergencyContact,
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      species: json['species'] as String? ?? '',
      breed: json['breed'] as String?,
      sex: json['sex'] as String?,
      birthDate: DateTime.tryParse(json['birth_date'] as String? ?? ''),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      color: json['color'] as String?,
      microchipNumber: json['microchip_number'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['photo_url'] as String?,
      notes: json['notes'] as String? ?? json['health_notes'] as String?,
      sterilized: json['sterilized'] as bool?,
      allergies: json['allergies'] as String?,
      chronicConditions: json['chronic_conditions'] as String?,
      ownerContactName: json['owner_contact_name'] as String?,
      ownerContactPhone: json['owner_contact_phone'] as String?,
      ownerContactEmail: json['owner_contact_email'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    String? sex,
    DateTime? birthDate,
    double? weightKg,
    String? color,
    String? microchipNumber,
    String? avatarUrl,
    String? notes,
    bool? sterilized,
    String? allergies,
    String? chronicConditions,
    String? ownerContactName,
    String? ownerContactPhone,
    String? ownerContactEmail,
    String? emergencyContact,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      color: color ?? this.color,
      microchipNumber: microchipNumber ?? this.microchipNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notes: notes ?? this.notes,
      sterilized: sterilized ?? this.sterilized,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      ownerContactName: ownerContactName ?? this.ownerContactName,
      ownerContactPhone: ownerContactPhone ?? this.ownerContactPhone,
      ownerContactEmail: ownerContactEmail ?? this.ownerContactEmail,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
