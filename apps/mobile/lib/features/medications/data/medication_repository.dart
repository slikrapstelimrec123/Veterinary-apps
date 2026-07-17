import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../pets/data/pet_repository.dart';
import '../domain/pet_medication.dart';

class MedicationRepository {
  bool get _useMock => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

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
      await _syncReminder(withId);
      return withId;
    }

    final row = await _client
        .from('pet_medications')
        .insert(medication.toInsertJson())
        .select()
        .single();

    final saved = PetMedication.fromJson(row);
    await _syncReminder(saved);
    return saved;
  }

  Future<PetMedication> updateMedication(PetMedication medication) async {
    if (_useMock) {
      final idx = _mockData.indexWhere((m) => m.id == medication.id);
      if (idx != -1) _mockData[idx] = medication;
      await _syncReminder(medication);
      return medication;
    }

    final row = await _client
        .from('pet_medications')
        .update(medication.toInsertJson())
        .eq('id', medication.id)
        .eq('pet_id', medication.petId)
        .select()
        .single();

    final saved = PetMedication.fromJson(row);
    await _syncReminder(saved);
    return saved;
  }

  Future<void> deleteMedication(String id) async {
    if (_useMock) {
      _mockData.removeWhere((m) => m.id == id);
      await _cancelReminder(id);
      return;
    }

    await _client.from('pet_medications').delete().eq('id', id);
    await _cancelReminder(id);
  }

  Future<void> _syncReminder(PetMedication medication) async {
    try {
      final dueDate = medication.nextDoseDate;
      if (!medication.reminderEnabled || dueDate == null) {
        await _cancelReminder(medication.id);
        return;
      }
      final pet = await PetRepository().getPet(medication.petId);
      await LocalNotificationService.instance.scheduleMedicationReminder(
        medicationId: medication.id,
        medicationName: medication.name,
        petName: pet?.name ?? 'Тварина',
        dueDate: dueDate,
      );
    } catch (_) {
      // The medication remains saved even if the OS rejects scheduling.
    }
  }

  Future<void> _cancelReminder(String medicationId) async {
    try {
      await LocalNotificationService.instance
          .cancelMedicationReminder(medicationId);
    } catch (_) {
      // A missing notification permission must not block medication changes.
    }
  }
}
