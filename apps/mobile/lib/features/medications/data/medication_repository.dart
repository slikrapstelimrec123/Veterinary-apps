import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/pet_medication.dart';

class MedicationRepository {
  bool get _useMock => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  static final List<PetMedication> _mockData = [
    PetMedication(
      id: 'mock_med_1',
      petId: 'mock_pet_luna',
      name: 'Bravecto (жувальна таблетка)',
      givenDate: DateTime.now().subtract(const Duration(days: 14)),
      dosage: '500 мг (1 таблетка)',
      category: 'tick_flea',
      notes: 'Захист від кліщів і бліх на 3 місяці.',
      nextDoseDate: DateTime.now().add(const Duration(days: 77)),
      reminderEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    PetMedication(
      id: 'mock_med_2',
      petId: 'mock_pet_luna',
      name: 'Мільбемакс (дегельмінтизація)',
      givenDate: DateTime.now().subtract(const Duration(days: 60)),
      dosage: '1 таблетка',
      category: 'deworming',
      notes: 'Планова дегельмінтизація кожні 3 місяці.',
      nextDoseDate: DateTime.now().add(const Duration(days: 30)),
      reminderEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    PetMedication(
      id: 'mock_med_3',
      petId: 'mock_pet_luna',
      name: 'Омега-3 (рибячий жир)',
      givenDate: DateTime.now().subtract(const Duration(days: 30)),
      dosage: '1 капсула на день',
      category: 'vitamin',
      notes: 'Для здоров\'я шкіри та шерсті.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    PetMedication(
      id: 'mock_med_4',
      petId: 'mock_pet_milo',
      name: 'Stronghold (краплі на холку)',
      givenDate: DateTime.now().subtract(const Duration(days: 7)),
      dosage: '0,75 мл (1 піпетка)',
      category: 'tick_flea',
      notes: 'Від бліх, кліщів та глистів.',
      nextDoseDate: DateTime.now().add(const Duration(days: 23)),
      reminderEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    PetMedication(
      id: 'mock_med_5',
      petId: 'mock_pet_milo',
      name: 'Паксіфор (дегельмінтизація)',
      givenDate: DateTime.now().subtract(const Duration(days: 45)),
      dosage: '½ таблетки',
      category: 'deworming',
      notes: 'Планова дегельмінтизація.',
      nextDoseDate: DateTime.now().add(const Duration(days: 45)),
      reminderEnabled: false,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    PetMedication(
      id: 'mock_med_6',
      petId: 'mock_pet_milo',
      name: 'Вітамінний комплекс Beaphar',
      givenDate: DateTime.now().subtract(const Duration(days: 10)),
      dosage: '1 таблетка на день',
      category: 'vitamin',
      notes: 'Мультивітаміни для підтримки імунітету.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  Future<List<PetMedication>> getMedications(String petId) async {
    if (_useMock) {
      return _mockData.where((m) => m.petId == petId).toList()
        ..sort((a, b) => b.givenDate.compareTo(a.givenDate));
    }

    final rows = await _client
        .from('pet_medications')
        .select()
        .eq('pet_id', petId)
        .order('given_date', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PetMedication.fromJson)
        .toList();
  }

  Future<PetMedication> addMedication(PetMedication medication) async {
    if (_useMock) {
      final withId = PetMedication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: medication.petId,
        name: medication.name,
        givenDate: medication.givenDate,
        dosage: medication.dosage,
        category: medication.category,
        notes: medication.notes,
        nextDoseDate: medication.nextDoseDate,
        reminderEnabled: medication.reminderEnabled,
        createdAt: DateTime.now(),
      );
      _mockData.add(withId);
      return withId;
    }

    final row = await _client
        .from('pet_medications')
        .insert(medication.toInsertJson())
        .select()
        .single();

    return PetMedication.fromJson(row);
  }

  Future<PetMedication> updateMedication(PetMedication medication) async {
    if (_useMock) {
      final idx = _mockData.indexWhere((m) => m.id == medication.id);
      if (idx != -1) _mockData[idx] = medication;
      return medication;
    }

    final row = await _client
        .from('pet_medications')
        .update(medication.toInsertJson())
        .eq('id', medication.id)
        .select()
        .single();

    return PetMedication.fromJson(row);
  }

  Future<void> deleteMedication(String id) async {
    if (_useMock) {
      _mockData.removeWhere((m) => m.id == id);
      return;
    }

    await _client.from('pet_medications').delete().eq('id', id);
  }
}
