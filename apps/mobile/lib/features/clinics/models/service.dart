class ClinicService {
  const ClinicService({
    required this.id,
    required this.clinicId,
    required this.name,
    this.category,
    this.description,
    this.durationMinutes = 30,
    this.priceAmount,
    this.priceCurrency = 'UAH',
    this.status = 'active',
    this.isPublic = true,
  });

  final String id;
  final String clinicId;
  final String name;
  final String? category;
  final String? description;
  final int durationMinutes;
  final double? priceAmount;
  final String priceCurrency;
  final String status;
  final bool isPublic;

  bool get isBookable => status == 'active' && isPublic;

  String get priceLabel {
    if (priceAmount == null) {
      return 'Ціну уточнює клініка';
    }

    return '${priceAmount!.toStringAsFixed(0)} $priceCurrency';
  }

  factory ClinicService.fromJson(Map<String, dynamic> json) {
    return ClinicService(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      description: json['description'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      priceAmount: (json['price_amount'] as num?)?.toDouble(),
      priceCurrency: json['price_currency'] as String? ?? 'UAH',
      status: json['status'] as String? ?? 'active',
      isPublic: json['is_public'] as bool? ?? true,
    );
  }
}
