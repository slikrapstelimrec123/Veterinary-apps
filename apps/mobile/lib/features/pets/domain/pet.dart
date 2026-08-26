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
    this.avatarStoragePath,
    this.notes,
    this.isNeutered,
    this.passportPhotoUrl,
    this.passportStoragePath,
    this.createdAt,
    this.updatedAt,
    this.emergencyAllergies,
    this.emergencyConditions,
    this.emergencySurgeries,
    this.emergencyContraindications,
    this.emergencyBehaviorNotes,
    this.emergencyBloodType,
    this.emergencyNotes,
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
  final String? avatarStoragePath;
  final String? notes;
  final bool? isNeutered;
  final String? passportPhotoUrl;
  final String? passportStoragePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? emergencyAllergies;
  final String? emergencyConditions;
  final String? emergencySurgeries;
  final String? emergencyContraindications;
  final String? emergencyBehaviorNotes;
  final String? emergencyBloodType;
  final String? emergencyNotes;

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
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }

    if (years <= 0) {
      final months =
          (now.year - birthDate!.year) * 12 + now.month - birthDate!.month;
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
      'avatar_storage_path': avatarStoragePath,
      'notes': notes,
      'is_neutered': isNeutered,
      'passport_photo_url': passportPhotoUrl,
      'passport_storage_path': passportStoragePath,
      'emergency_allergies': emergencyAllergies,
      'emergency_conditions': emergencyConditions,
      'emergency_surgeries': emergencySurgeries,
      'emergency_contraindications': emergencyContraindications,
      'emergency_behavior_notes': emergencyBehaviorNotes,
      'emergency_blood_type': emergencyBloodType,
      'emergency_notes': emergencyNotes,
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
      avatarStoragePath: json['avatar_storage_path'] as String?,
      notes: json['notes'] as String? ?? json['health_notes'] as String?,
      isNeutered: json['is_neutered'] as bool?,
      passportPhotoUrl: json['passport_photo_url'] as String?,
      passportStoragePath: json['passport_storage_path'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      emergencyAllergies: json['emergency_allergies'] as String?,
      emergencyConditions: json['emergency_conditions'] as String?,
      emergencySurgeries: json['emergency_surgeries'] as String?,
      emergencyContraindications:
          json['emergency_contraindications'] as String?,
      emergencyBehaviorNotes: json['emergency_behavior_notes'] as String?,
      emergencyBloodType: json['emergency_blood_type'] as String?,
      emergencyNotes: json['emergency_notes'] as String?,
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
    String? avatarStoragePath,
    String? notes,
    bool? isNeutered,
    String? passportPhotoUrl,
    String? passportStoragePath,
    String? emergencyAllergies,
    String? emergencyConditions,
    String? emergencySurgeries,
    String? emergencyContraindications,
    String? emergencyBehaviorNotes,
    String? emergencyBloodType,
    String? emergencyNotes,
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
      avatarStoragePath: avatarStoragePath ?? this.avatarStoragePath,
      notes: notes ?? this.notes,
      isNeutered: isNeutered ?? this.isNeutered,
      passportPhotoUrl: passportPhotoUrl ?? this.passportPhotoUrl,
      passportStoragePath: passportStoragePath ?? this.passportStoragePath,
      createdAt: createdAt,
      updatedAt: updatedAt,
      emergencyAllergies: emergencyAllergies ?? this.emergencyAllergies,
      emergencyConditions: emergencyConditions ?? this.emergencyConditions,
      emergencySurgeries: emergencySurgeries ?? this.emergencySurgeries,
      emergencyContraindications:
          emergencyContraindications ?? this.emergencyContraindications,
      emergencyBehaviorNotes:
          emergencyBehaviorNotes ?? this.emergencyBehaviorNotes,
      emergencyBloodType: emergencyBloodType ?? this.emergencyBloodType,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
    );
  }
}
