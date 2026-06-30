class Review {
  const Review({
    required this.id,
    required this.clinicId,
    required this.appointmentId,
    required this.petId,
    required this.ownerId,
    required this.rating,
    required this.status,
    required this.createdAt,
    this.doctorId,
    this.visitRecordId,
    this.doctorRating,
    this.clinicRating,
    this.serviceQualityRating,
    this.comment,
    this.isAnonymous = false,
    this.ownerName,
    this.doctorName,
  });

  final String id;
  final String clinicId;
  final String? doctorId;
  final String appointmentId;
  final String? visitRecordId;
  final String petId;
  final String ownerId;
  final int rating;
  final int? doctorRating;
  final int? clinicRating;
  final int? serviceQualityRating;
  final String? comment;
  final String status;
  final bool isAnonymous;
  final DateTime createdAt;
  final String? ownerName;
  final String? doctorName;

  bool get isPublished => status == 'published';
  String get authorLabel => isAnonymous ? 'Анонімний власник тварини' : ownerName ?? 'Власник тварини';

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final doctor = json['doctors'];

    return Review(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String? ?? '',
      doctorId: json['doctor_id'] as String?,
      appointmentId: json['appointment_id'] as String? ?? '',
      visitRecordId: json['visit_record_id'] as String?,
      petId: json['pet_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      doctorRating: (json['doctor_rating'] as num?)?.toInt(),
      clinicRating: (json['clinic_rating'] as num?)?.toInt(),
      serviceQualityRating: (json['service_quality_rating'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      status: json['status'] as String? ?? (json['is_published'] == true ? 'published' : 'hidden'),
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      ownerName: profile is Map<String, dynamic> ? profile['full_name'] as String? : json['owner_name'] as String?,
      doctorName: doctor is Map<String, dynamic> ? doctor['full_name'] as String? : json['doctor_name'] as String?,
    );
  }
}

class RatingSummary {
  const RatingSummary({
    required this.averageRating,
    required this.reviewCount,
    this.latestReviewDate,
    this.secondaryAverage,
  });

  final double averageRating;
  final int reviewCount;
  final DateTime? latestReviewDate;
  final double? secondaryAverage;

  bool get hasReviews => reviewCount > 0;

  factory RatingSummary.fromJson(Map<String, dynamic>? json, {String secondaryKey = 'average_clinic_rating'}) {
    if (json == null) {
      return const RatingSummary(averageRating: 0, reviewCount: 0);
    }

    return RatingSummary(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      secondaryAverage: (json[secondaryKey] as num?)?.toDouble(),
      latestReviewDate: DateTime.tryParse(json['latest_review_date'] as String? ?? ''),
    );
  }
}
