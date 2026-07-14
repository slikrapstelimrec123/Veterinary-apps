import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/pet_feeding.dart';

class FeedingRepository {
  bool get _useMock => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  static final List<PetFeeding> _mockData = [];

  Future<List<PetFeeding>> getFeedings(String petId) async {
    if (_useMock) {
      return _mockData.where((f) => f.petId == petId).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
    }

    final rows = await _client
        .from('pet_feedings')
        .select()
        .eq('pet_id', petId)
        .order('start_date', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PetFeeding.fromJson)
        .toList();
  }

  Future<PetFeeding> addFeeding(PetFeeding feeding) async {
    if (_useMock) {
      final withId = PetFeeding(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: feeding.petId,
        foodName: feeding.foodName,
        brand: feeding.brand,
        foodType: feeding.foodType,
        startDate: feeding.startDate,
        endDate: feeding.endDate,
        notes: feeding.notes,
        rating: feeding.rating,
        createdAt: DateTime.now(),
      );
      _mockData.add(withId);
      return withId;
    }

    final row = await _client
        .from('pet_feedings')
        .insert(feeding.toInsertJson())
        .select()
        .single();

    return PetFeeding.fromJson(row);
  }

  Future<PetFeeding> updateFeeding(PetFeeding feeding) async {
    if (_useMock) {
      final idx = _mockData.indexWhere((f) => f.id == feeding.id);
      if (idx != -1) _mockData[idx] = feeding;
      return feeding;
    }

    final row = await _client
        .from('pet_feedings')
        .update(feeding.toInsertJson())
        .eq('id', feeding.id)
        .select()
        .single();

    return PetFeeding.fromJson(row);
  }

  Future<void> deleteFeeding(String id) async {
    if (_useMock) {
      _mockData.removeWhere((f) => f.id == id);
      return;
    }

    await _client.from('pet_feedings').delete().eq('id', id);
  }
}
