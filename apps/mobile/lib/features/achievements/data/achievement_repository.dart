import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/data/app_data_events.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../domain/pet_achievement.dart';

class AchievementRepository {
  bool get _useMock => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  static final List<PetAchievement> _mockData = [];

  Future<List<PetAchievement>> getAchievements(String petId) async {
    if (_useMock) {
      return _mockData.where((a) => a.petId == petId).toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
    }

    final rows = await _client
        .from('pet_achievements')
        .select()
        .eq('pet_id', petId)
        .order('event_date', ascending: false);

    return Future.wait((rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(_fromPrivateRow));
  }

  Future<PetAchievement> addAchievement(PetAchievement achievement) async {
    if (_useMock) {
      final withId = PetAchievement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: achievement.petId,
        title: achievement.title,
        eventDate: achievement.eventDate,
        endDate: achievement.endDate,
        eventType: achievement.eventType,
        location: achievement.location,
        result: achievement.result,
        awardTitle: achievement.awardTitle,
        awardImageUrl: achievement.awardImageUrl,
        eventPhotoUrl: achievement.eventPhotoUrl,
        awardImagePath: achievement.awardImagePath,
        eventPhotoPath: achievement.eventPhotoPath,
        notes: achievement.notes,
        createdAt: DateTime.now(),
      );
      _mockData.add(withId);
      AppDataEvents.notifyChanged();
      return withId;
    }

    final row = await _client
        .from('pet_achievements')
        .insert(achievement.toInsertJson())
        .select()
        .single();

    final saved = await _fromPrivateRow(row);
    AppDataEvents.notifyChanged();
    return saved;
  }

  Future<PetAchievement> updateAchievement(PetAchievement achievement) async {
    if (_useMock) {
      final idx = _mockData.indexWhere((a) => a.id == achievement.id);
      if (idx != -1) _mockData[idx] = achievement;
      AppDataEvents.notifyChanged();
      return achievement;
    }

    final row = await _client
        .from('pet_achievements')
        .update(achievement.toInsertJson())
        .eq('id', achievement.id)
        .eq('pet_id', achievement.petId)
        .select()
        .single();

    final saved = await _fromPrivateRow(row);
    AppDataEvents.notifyChanged();
    return saved;
  }

  Future<void> deleteAchievement(String id) async {
    if (_useMock) {
      _mockData.removeWhere((a) => a.id == id);
      AppDataEvents.notifyChanged();
      return;
    }

    await _client.from('pet_achievements').delete().eq('id', id);
    AppDataEvents.notifyChanged();
  }

  Future<PetAchievement> _fromPrivateRow(Map<String, dynamic> row) async {
    final hydrated = Map<String, dynamic>.from(row);
    try {
      hydrated['award_image_url'] = await PrivatePetStorage.signedUrl(
            row['award_image_path'] as String?,
          ) ??
          row['award_image_url'];
      hydrated['event_photo_url'] = await PrivatePetStorage.signedUrl(
            row['event_photo_path'] as String?,
          ) ??
          row['event_photo_url'];
    } catch (_) {
      // Preserve legacy URLs if signing is temporarily unavailable.
    }
    return PetAchievement.fromJson(hydrated);
  }
}
