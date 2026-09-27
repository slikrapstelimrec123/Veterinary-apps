enum CommunityAnnouncementType {
  event('event', 'Події'),
  service('service', 'Послуги'),
  offer('offer', 'Пропозиції');

  const CommunityAnnouncementType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static CommunityAnnouncementType fromDatabase(String value) {
    return values.firstWhere(
      (type) => type.databaseValue == value,
      orElse: () => CommunityAnnouncementType.event,
    );
  }
}

enum ServiceCategory {
  dogTrainer('dog_trainer', 'Кінолог'),
  groomer('groomer', 'Грумер'),
  petSitter('pet_sitter', 'Петсіттер'),
  dogHotel('dog_hotel', 'Готель для собак');

  const ServiceCategory(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static ServiceCategory? fromDatabase(String? value) {
    if (value == null) return null;
    for (final category in values) {
      if (category.databaseValue == value) return category;
    }
    return null;
  }
}

enum OfferCategory {
  shop('shop', 'Магазин'),
  clinic('clinic', 'Клініка'),
  other('other', 'Інше');

  const OfferCategory(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static OfferCategory? fromDatabase(String? value) {
    if (value == null) return null;
    for (final category in values) {
      if (category.databaseValue == value) return category;
    }
    return null;
  }
}

class CommunityAnnouncement {
  const CommunityAnnouncement({
    required this.id,
    required this.type,
    required this.title,
    required this.address,
    required this.city,
    required this.description,
    required this.createdAt,
    this.eventDate,
    this.contact,
    this.serviceCategory,
    this.offerCategory,
    this.priceAmount,
    this.website,
    this.offerText,
    this.validFrom,
    this.validUntil,
    this.promoCode,
    this.photoUrl,
    this.photoStoragePath,
    this.isActive = true,
    this.ownerId,
    this.viewCount = 0,
    this.listingCreditId,
    this.latitude,
    this.longitude,
  });

  final String id;
  final CommunityAnnouncementType type;
  final String title;
  final String address;
  final String city;
  final String description;
  final DateTime createdAt;
  final DateTime? eventDate;
  final String? contact;
  final ServiceCategory? serviceCategory;
  final OfferCategory? offerCategory;
  final int? priceAmount;
  final String? website;
  final String? offerText;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? promoCode;
  final String? photoUrl;
  final String? photoStoragePath;
  final bool isActive;
  final String? ownerId;
  final int viewCount;
  final String? listingCreditId;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isMobileService {
    if (type != CommunityAnnouncementType.service) return false;
    final text = '${address.toLowerCase()} ${description.toLowerCase()}';
    return RegExp(
      r'виїзд|виїзн|за адресою клієнта|на дому|по місту|у клієнта',
    ).hasMatch(text);
  }

  factory CommunityAnnouncement.fromJson(Map<String, dynamic> json) {
    return CommunityAnnouncement(
      id: json['id'] as String,
      type: CommunityAnnouncementType.fromDatabase(
        json['announcement_type'] as String? ?? 'event',
      ),
      title: json['title'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      eventDate: DateTime.tryParse(json['event_date'] as String? ?? ''),
      contact: json['contact_info'] as String?,
      serviceCategory:
          ServiceCategory.fromDatabase(json['service_category'] as String?),
      offerCategory:
          OfferCategory.fromDatabase(json['offer_category'] as String?),
      priceAmount: (json['price_amount'] as num?)?.toInt(),
      website: json['website'] as String?,
      offerText: json['offer_text'] as String?,
      validFrom: DateTime.tryParse(json['valid_from'] as String? ?? ''),
      validUntil: DateTime.tryParse(json['valid_until'] as String? ?? ''),
      promoCode: json['promo_code'] as String?,
      photoUrl: json['cover_photo_url'] as String?,
      photoStoragePath: json['cover_photo_storage_path'] as String?,
      isActive: json['status'] == 'active',
      ownerId: json['owner_id'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      listingCreditId: json['listing_credit_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson({required String currentOwnerId}) => {
        'id': id,
        'owner_id': currentOwnerId,
        'pet_id': null,
        'announcement_type': type.databaseValue,
        'title': title,
        'address': address,
        'city': city,
        'description': description,
        'event_date': eventDate?.toUtc().toIso8601String(),
        'contact_info': contact,
        'service_category': serviceCategory?.databaseValue,
        'offer_category': offerCategory?.databaseValue,
        'price_amount': priceAmount,
        'website': website,
        'offer_text': offerText,
        'valid_from': validFrom?.toIso8601String().split('T').first,
        'valid_until': validUntil?.toIso8601String().split('T').first,
        'promo_code': promoCode,
        'cover_photo_url': photoUrl,
        'cover_photo_storage_path': photoStoragePath,
        'listing_credit_id': listingCreditId,
        'latitude': latitude,
        'longitude': longitude,
      };

  Map<String, dynamic> toUpdateJson() {
    final values = toJson(currentOwnerId: ownerId ?? '');
    values.remove('id');
    values.remove('owner_id');
    values.remove('pet_id');
    values.remove('announcement_type');
    return values;
  }

  CommunityAnnouncement copyWithCoordinates({
    required double? latitude,
    required double? longitude,
  }) {
    return CommunityAnnouncement(
      id: id,
      type: type,
      title: title,
      address: address,
      city: city,
      description: description,
      createdAt: createdAt,
      eventDate: eventDate,
      contact: contact,
      serviceCategory: serviceCategory,
      offerCategory: offerCategory,
      priceAmount: priceAmount,
      website: website,
      offerText: offerText,
      validFrom: validFrom,
      validUntil: validUntil,
      promoCode: promoCode,
      photoUrl: photoUrl,
      photoStoragePath: photoStoragePath,
      isActive: isActive,
      ownerId: ownerId,
      viewCount: viewCount,
      listingCreditId: listingCreditId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  String get subtitle {
    return switch (type) {
      CommunityAnnouncementType.event => _dateLabel(eventDate),
      CommunityAnnouncementType.service =>
        '${serviceCategory?.label ?? 'Послуга'}${priceAmount == null ? '' : ' · $priceAmount грн'}',
      CommunityAnnouncementType.offer => validUntil == null
          ? offerCategory?.label ?? 'Спеціальна пропозиція'
          : '${offerCategory?.label ?? 'Пропозиція'} · діє до ${_dateLabel(validUntil)}',
    };
  }

  static String _dateLabel(DateTime? value) {
    if (value == null) return 'Дата не вказана';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }
}
