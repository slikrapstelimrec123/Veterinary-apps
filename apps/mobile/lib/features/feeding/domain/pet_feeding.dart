class PetFeeding {
  const PetFeeding({
    required this.id,
    required this.petId,
    required this.foodName,
    required this.startDate,
    this.brand,
    this.foodType,
    this.endDate,
    this.notes,
    this.rating,
    this.createdAt,
  });

  final String id;
  final String petId;
  final String foodName;
  final String? brand;
  final String? foodType;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final int? rating;
  final DateTime? createdAt;

  bool get isCurrent => endDate == null;

  String get foodTypeLabel => switch (foodType) {
        'dry' => 'Сухий корм',
        'wet' => 'Вологий корм',
        'raw' => 'Натуральне харчування',
        'mixed' => 'Змішане',
        'prescription' => 'Лікувальний корм',
        _ => foodType ?? 'Інше',
      };

  factory PetFeeding.fromJson(Map<String, dynamic> json) {
    return PetFeeding(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      foodName: json['food_name'] as String,
      brand: json['brand'] as String?,
      foodType: json['food_type'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      notes: json['notes'] as String?,
      rating: json['rating'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'pet_id': petId,
        'food_name': foodName,
        'brand': brand,
        'food_type': foodType,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'notes': notes,
        'rating': rating,
      };
}
