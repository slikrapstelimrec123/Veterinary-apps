import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/pet_medication.dart';

class MedicationRepository {
  bool get _useMock => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  // In-memory store for mock/demo mode
  static final List<PetMedication> _mockData = [];

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

  Future<void> deleteMedication(String id) async {
    if (_useMock) {
      _mockData.removeWhere((m) => m.id == id);
      return;
    }

    await _client.from('pet_medications').delete().eq('id', id);
  }
}
