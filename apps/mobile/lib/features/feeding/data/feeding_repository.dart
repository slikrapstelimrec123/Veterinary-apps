import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/pet_feeding.dart';

class FeedingRepository {
  bool get _useMock => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  static final List<PetFeeding> _mockData = [
    PetFeeding(
      id: 'mock_feed_1',
      petId: 'mock_pet_luna',
      foodName: 'Adult Sensitive Digestion',
      brand: 'Royal Canin',
      foodType: 'dry',
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      rating: 5,
      notes: 'Добре переноситься, стілець нормалізувався після переходу на цей корм.',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    PetFeeding(
      id: 'mock_feed_2',
      petId: 'mock_pet_luna',
      foodName: 'Puppy Maxi (попередній)',
      brand: 'Purina Pro Plan',
      foodType: 'dry',
      startDate: DateTime(2022, 4, 12),
      endDate: DateTime.now().subtract(const Duration(days: 91)),
      rating: 4,
      notes: 'Корм для цуценят до переходу на дорослий раціон.',
      createdAt: DateTime(2022, 4, 12),
    ),
    PetFeeding(
      id: 'mock_feed_3',
      petId: 'mock_pet_luna',
      foodName: 'Вологий корм з куркою',
      brand: 'Pedigree',
      foodType: 'wet',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      rating: 3,
      notes: 'Як доповнення до сухого корму, 1 пакетик на день.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    PetFeeding(
      id: 'mock_feed_4',
      petId: 'mock_pet_milo',
      foodName: 'Indoor Adult',
      brand: 'Hill\'s Science Plan',
      foodType: 'dry',
      startDate: DateTime.now().subtract(const Duration(days: 120)),
      rating: 5,
      notes: 'Відмінно підходить для домашнього кота. Вага стабільна.',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    PetFeeding(
      id: 'mock_feed_5',
      petId: 'mock_pet_milo',
      foodName: 'Sterilised з тунцем',
      brand: 'Whiskas',
      foodType: 'wet',
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      rating: 4,
      notes: 'Вологий корм вранці. Milo їсть із задоволенням.',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    PetFeeding(
      id: 'mock_feed_6',
      petId: 'mock_pet_milo',
      foodName: 'Urinary Care (лікувальний)',
      brand: 'Royal Canin',
      foodType: 'prescription',
      startDate: DateTime.now().subtract(const Duration(days: 200)),
      endDate: DateTime.now().subtract(const Duration(days: 121)),
      rating: 4,
      notes: 'Призначений ветеринаром після виявлення кристалів у сечі. Курс завершено.',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
    ),
  ];

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
