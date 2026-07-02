class PetMedication {
  const PetMedication({
    required this.id,
    required this.petId,
    required this.name,
    required this.givenDate,
    this.dosage,
    this.category,
    this.notes,
    this.nextDoseDate,
    this.reminderEnabled = false,
    this.createdAt,
  });

  final String id;
  final String petId;
  final String name;
  final DateTime givenDate;
  final String? dosage;
  final String? category;
  final String? notes;
  final DateTime? nextDoseDate;
  final bool reminderEnabled;
  final DateTime? createdAt;

  String get categoryLabel {
    return switch (category) {
      'tick_flea' => 'Від кліщів / бліх',
      'deworming' => 'Дегельмінтизація',
      'vitamin' => 'Вітаміни / добавки',
      'antibiotic' => 'Антибіотик',
      'other' => 'Інше',
      _ => category ?? 'Інше',
    };
  }

  bool get nextDoseOverdue {
    if (nextDoseDate == null) return false;
    return nextDoseDate!.isBefore(DateTime.now());
  }

  bool get nextDueSoon {
    if (nextDoseDate == null) return false;
    final diff = nextDoseDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  factory PetMedication.fromJson(Map<String, dynamic> json) {
    return PetMedication(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      name: json['name'] as String,
      givenDate: DateTime.parse(json['given_date'] as String),
      dosage: json['dosage'] as String?,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      nextDoseDate: json['next_dose_date'] != null ? DateTime.tryParse(json['next_dose_date'] as String) : null,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'pet_id': petId,
      'name': name,
      'given_date': givenDate.toIso8601String().split('T').first,
      'dosage': dosage,
      'category': category,
      'notes': notes,
      'next_dose_date': nextDoseDate?.toIso8601String().split('T').first,
      'reminder_enabled': reminderEnabled,
    };
  }
}
