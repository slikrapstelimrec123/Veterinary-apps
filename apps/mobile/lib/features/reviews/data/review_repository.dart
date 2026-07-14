import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../../appointments/models/appointment.dart';
import '../../visit_records/domain/visit_record.dart';
import '../domain/review.dart';

class ReviewRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Review>> getClinicReviews(String clinicId,
      {bool includeNonPublished = false}) async {
    if (_useMockData) {
      return _sorted(MockData.reviews.where((review) =>
          review.clinicId == clinicId &&
          (includeNonPublished || review.status == 'published')));
    }

    var query = _client
        .from('reviews')
        .select('*, profiles(full_name), doctors(full_name)')
        .eq('clinic_id', clinicId);
    if (!includeNonPublished) {
      query = query.eq('status', 'published');
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList();
  }

  Future<List<Review>> getDoctorReviews(String doctorId) async {
    if (_useMockData) {
      return _sorted(MockData.reviews.where((review) =>
          review.doctorId == doctorId && review.status == 'published'));
    }

    final rows = await _client
        .from('reviews')
        .select('*, profiles(full_name), doctors(full_name)')
        .eq('doctor_id', doctorId)
        .eq('status', 'published')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList();
  }

  Future<RatingSummary> getClinicSummary(String clinicId) async {
    if (_useMockData) {
      return _summary(
          MockData.reviews.where((review) =>
              review.clinicId == clinicId && review.status == 'published'),
          secondary: (review) => review.clinicRating);
    }

    final row = await _client
        .from('clinic_rating_summary')
        .select('*')
        .eq('clinic_id', clinicId)
        .maybeSingle();
    return RatingSummary.fromJson(row, secondaryKey: 'average_clinic_rating');
  }

  Future<RatingSummary> getDoctorSummary(String doctorId) async {
    if (_useMockData) {
      return _summary(
          MockData.reviews.where((review) =>
              review.doctorId == doctorId && review.status == 'published'),
          secondary: (review) => review.doctorRating);
    }

    final row = await _client
        .from('doctor_rating_summary')
        .select('*')
        .eq('doctor_id', doctorId)
        .maybeSingle();
    return RatingSummary.fromJson(row, secondaryKey: 'average_doctor_rating');
  }

  Future<Review?> getReviewForAppointment(String appointmentId) async {
    if (_useMockData) {
      for (final review in MockData.reviews) {
        if (review.appointmentId == appointmentId &&
            review.ownerId == 'mock_pet_owner' &&
            review.status != 'removed') {
          return review;
        }
      }
      return null;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final row = await _client
        .from('reviews')
        .select('*, profiles(full_name), doctors(full_name)')
        .eq('appointment_id', appointmentId)
        .eq('owner_id', userId)
        .maybeSingle();
    return row == null ? null : Review.fromJson(row);
  }

  Future<bool> canLeaveReviewForAppointment(Appointment appointment,
      {VisitRecord? visitRecord}) async {
    final existing = await getReviewForAppointment(appointment.id);
    if (existing != null) {
      return false;
    }

    return appointment.status == 'completed' ||
        visitRecord?.status == 'published';
  }

  Future<Review> submitReview({
    required String clinicId,
    required String? doctorId,
    required String appointmentId,
    required String? visitRecordId,
    required String petId,
    required int rating,
    int? doctorRating,
    int? clinicRating,
    int? serviceQualityRating,
    String? comment,
    required bool isAnonymous,
  }) async {
    final ownerId =
        _useMockData ? 'mock_pet_owner' : _client.auth.currentUser!.id;
    final payload = <String, dynamic>{
      'clinic_id': clinicId,
      'doctor_id': doctorId,
      'appointment_id': appointmentId,
      'visit_record_id': visitRecordId,
      'pet_id': petId,
      'owner_id': ownerId,
      'rating': rating,
      'doctor_rating': doctorRating,
      'clinic_rating': clinicRating,
      'service_quality_rating': serviceQualityRating,
      'comment': comment,
      'is_anonymous': isAnonymous,
      'status': 'pending',
      'is_published': false,
    };

    if (_useMockData) {
      if (MockData.reviews.any((review) =>
          review.appointmentId == appointmentId && review.ownerId == ownerId)) {
        throw StateError('duplicate');
      }
      final review = Review.fromJson({
        ...payload,
        'id': 'mock_review_${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
        'owner_name': 'Олена Петренко',
      });
      MockData.reviews.insert(0, review);
      return review;
    }

    final row = await _client
        .from('reviews')
        .insert(payload)
        .select('*, profiles(full_name), doctors(full_name)')
        .single();
    return Review.fromJson(row);
  }

  List<Review> _sorted(Iterable<Review> reviews) {
    return reviews.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  RatingSummary _summary(Iterable<Review> source,
      {required int? Function(Review review) secondary}) {
    final rows = source.toList();
    if (rows.isEmpty) {
      return const RatingSummary(averageRating: 0, reviewCount: 0);
    }

    final secondaryRows = rows.map(secondary).whereType<int>().toList();
    return RatingSummary(
      averageRating:
          rows.map((review) => review.rating).reduce((a, b) => a + b) /
              rows.length,
      reviewCount: rows.length,
      secondaryAverage: secondaryRows.isEmpty
          ? null
          : secondaryRows.reduce((a, b) => a + b) / secondaryRows.length,
      latestReviewDate: rows
          .map((review) => review.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }
}
