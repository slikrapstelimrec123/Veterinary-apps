import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
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

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PetAchievement.fromJson)
        .toList();
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
        notes: achievement.notes,
        createdAt: DateTime.now(),
      );
      _mockData.add(withId);
      return withId;
    }

    final row = await _client
        .from('pet_achievements')
        .insert(achievement.toInsertJson())
        .select()
        .single();

    return PetAchievement.fromJson(row);
  }

  Future<PetAchievement> updateAchievement(PetAchievement achievement) async {
    if (_useMock) {
      final idx = _mockData.indexWhere((a) => a.id == achievement.id);
      if (idx != -1) _mockData[idx] = achievement;
      return achievement;
    }

    final row = await _client
        .from('pet_achievements')
        .update(achievement.toInsertJson())
        .eq('id', achievement.id)
        .select()
        .single();

    return PetAchievement.fromJson(row);
  }

  Future<void> deleteAchievement(String id) async {
    if (_useMock) {
      _mockData.removeWhere((a) => a.id == id);
      return;
    }

    await _client.from('pet_achievements').delete().eq('id', id);
  }
}
