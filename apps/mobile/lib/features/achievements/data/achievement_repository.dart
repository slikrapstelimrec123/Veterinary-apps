import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/pet_achievement.dart';

class AchievementRepository {
  bool get _useMock => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  static final List<PetAchievement> _mockData = [
    PetAchievement(
      id: 'mock_ach_1',
      petId: 'mock_pet_luna',
      title: 'Виставка порід — Київ 2024',
      eventDate: DateTime(2024, 10, 5),
      eventType: 'exhibition',
      location: 'МВЦ, Київ',
      result: '1 місце у класі юніорів',
      awardTitle: 'Кращий юніор виставки',
      notes: 'Luna отримала найвищий бал від всіх суддів.',
      createdAt: DateTime(2024, 10, 6),
    ),
    PetAchievement(
      id: 'mock_ach_2',
      petId: 'mock_pet_luna',
      title: 'Аджиліті — Осінній кубок',
      eventDate: DateTime(2024, 9, 14),
      eventType: 'competition',
      location: 'Спортивний парк «Пролісок», Київ',
      result: '2 місце',
      awardTitle: 'Срібна нагорода',
      notes: 'Пройшла трасу без штрафних балів за 28,4 с.',
      createdAt: DateTime(2024, 9, 15),
    ),
    PetAchievement(
      id: 'mock_ach_3',
      petId: 'mock_pet_luna',
      title: 'Базовий курс послуху',
      eventDate: DateTime(2024, 6, 20),
      endDate: DateTime(2024, 8, 15),
      eventType: 'training',
      location: 'Кінологічний центр «Вірний друг»',
      result: 'Зараховано',
      awardTitle: 'Сертифікат базового послуху',
      notes: 'Відмінно освоїла команди «сидіти», «лежати», «місце», «підійди».',
      createdAt: DateTime(2024, 8, 16),
    ),
    PetAchievement(
      id: 'mock_ach_4',
      petId: 'mock_pet_milo',
      title: 'Виставка котів — Весна 2024',
      eventDate: DateTime(2024, 4, 20),
      eventType: 'exhibition',
      location: 'Палац культури «Жовтень», Київ',
      result: '3 місце у класі дорослих',
      awardTitle: 'Бронзова медаль',
      notes: 'Milo чудово себе поводив під час виставки.',
      createdAt: DateTime(2024, 4, 21),
    ),
    PetAchievement(
      id: 'mock_ach_5',
      petId: 'mock_pet_milo',
      title: 'Сертифікат здоров\'я WCF',
      eventDate: DateTime(2024, 3, 10),
      eventType: 'certification',
      location: 'Ветклініка Північна Зірка',
      result: 'Пройдено',
      awardTitle: 'Сертифікат здоров\'я WCF 2024',
      notes: 'Щорічне підтвердження стану здоров\'я для реєстру WCF.',
      createdAt: DateTime(2024, 3, 10),
    ),
  ];

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
