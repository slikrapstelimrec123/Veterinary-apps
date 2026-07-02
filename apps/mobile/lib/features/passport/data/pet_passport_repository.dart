import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/pet_passport_models.dart';

class PetPassportRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<PetHealthEvent>> getHealthEvents({String? petId}) async {
    if (_useMockData) {
      return _DemoPassportData.healthEvents.where((event) => petId == null || event.petId == petId).toList();
    }

    final data = petId == null
        ? await _client.from('pet_health_events').select('*').order('date_done', ascending: false)
        : await _client.from('pet_health_events').select('*').eq('pet_id', petId).order('date_done', ascending: false);
    return (data as List<dynamic>).whereType<Map<String, dynamic>>().map(PetHealthEvent.fromJson).toList();
  }

  Future<List<PetDocument>> getDocuments({String? petId}) async {
    if (_useMockData) {
      return _DemoPassportData.documents.where((document) => petId == null || document.petId == petId).toList();
    }

    final data = petId == null
        ? await _client.from('pet_documents').select('*').order('created_at', ascending: false)
        : await _client.from('pet_documents').select('*').eq('pet_id', petId).order('created_at', ascending: false);
    return (data as List<dynamic>).whereType<Map<String, dynamic>>().map(PetDocument.fromJson).toList();
  }

  Future<List<PetReminder>> getReminders({String? petId}) async {
    if (_useMockData) {
      return _DemoPassportData.reminders.where((reminder) => petId == null || reminder.petId == petId).toList();
    }

    final data = petId == null
        ? await _client.from('pet_reminders').select('*').order('due_date', ascending: true)
        : await _client.from('pet_reminders').select('*').eq('pet_id', petId).order('due_date', ascending: true);
    return (data as List<dynamic>).whereType<Map<String, dynamic>>().map(PetReminder.fromJson).toList();
  }

  Future<PetPublicProfile?> getPublicProfile(String petId) async {
    if (_useMockData) {
      for (final profile in _DemoPassportData.publicProfiles) {
        if (profile.petId == petId) {
          return profile;
        }
      }
      return null;
    }

    final data = await _client.from('pet_public_profiles').select('*').eq('pet_id', petId).maybeSingle();
    return data == null ? null : PetPublicProfile.fromJson(data);
  }

  Future<void> markReminderCompleted(String id) async {
    if (_useMockData) {
      final index = _DemoPassportData.reminders.indexWhere((reminder) => reminder.id == id);
      if (index >= 0) {
        final current = _DemoPassportData.reminders[index];
        _DemoPassportData.reminders[index] = PetReminder(
          id: current.id,
          petId: current.petId,
          type: current.type,
          title: current.title,
          dueDate: current.dueDate,
          status: 'completed',
          description: current.description,
          repeatRule: current.repeatRule,
        );
      }
      return;
    }

    await _client.from('pet_reminders').update({'status': 'completed'}).eq('id', id);
  }
}

class _DemoPassportData {
  static final healthEvents = <PetHealthEvent>[
    PetHealthEvent(
      id: 'mock_health_1',
      petId: 'mock_pet_luna',
      type: 'vaccination',
      title: 'Комплексна вакцинація',
      dateDone: DateTime.now().subtract(const Duration(days: 335)),
      nextDueDate: DateTime.now().add(const Duration(days: 30)),
      clinicName: 'Ветклініка Північна Зірка',
      doctorName: 'Лікар Анна Коваленко',
      notes: 'Реакції після вакцинації не було.',
    ),
    PetHealthEvent(
      id: 'mock_health_2',
      petId: 'mock_pet_luna',
      type: 'tick_treatment',
      title: 'Обробка від кліщів',
      dateDone: DateTime.now().subtract(const Duration(days: 23)),
      nextDueDate: DateTime.now().add(const Duration(days: 7)),
      notes: 'Краплі на холку, повторити через місяць.',
    ),
    PetHealthEvent(
      id: 'mock_health_3',
      petId: 'mock_pet_milo',
      type: 'vaccination',
      title: 'Щорічна вакцинація',
      dateDone: DateTime.now().subtract(const Duration(days: 360)),
      nextDueDate: DateTime.now().add(const Duration(days: 5)),
      clinicName: 'Ветеринарія Зелена Лапа',
    ),
  ];

  static final documents = <PetDocument>[
    PetDocument(
      id: 'mock_passport_doc_1',
      petId: 'mock_pet_luna',
      title: 'Скан ветеринарного паспорта',
      documentType: 'vet_passport',
      fileName: 'luna-vet-passport.pdf',
      documentDate: DateTime.now().subtract(const Duration(days: 335)),
      description: 'Перші сторінки паспорта та позначка вакцинації.',
    ),
    PetDocument(
      id: 'mock_passport_doc_2',
      petId: 'mock_pet_milo',
      title: 'Довідка про вакцинацію',
      documentType: 'vaccination',
      fileName: 'milo-vaccination.pdf',
      documentDate: DateTime.now().subtract(const Duration(days: 360)),
    ),
  ];

  static final reminders = <PetReminder>[
    PetReminder(
      id: 'mock_reminder_1',
      petId: 'mock_pet_luna',
      type: 'tick_treatment',
      title: 'Повторити обробку від кліщів',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      status: 'upcoming',
      repeatRule: 'Щомісяця',
    ),
    PetReminder(
      id: 'mock_reminder_2',
      petId: 'mock_pet_milo',
      type: 'vaccination',
      title: 'Щорічна вакцинація Milo',
      dueDate: DateTime.now().add(const Duration(days: 5)),
      status: 'upcoming',
      repeatRule: 'Щороку',
    ),
  ];

  static const publicProfiles = <PetPublicProfile>[
    PetPublicProfile(
      id: 'mock_public_1',
      petId: 'mock_pet_luna',
      publicSlug: 'luna-safe-card',
      isEnabled: true,
      publicNote: 'Якщо ви знайшли Luna, будь ласка, звʼяжіться з власником.',
    ),
    PetPublicProfile(
      id: 'mock_public_2',
      petId: 'mock_pet_milo',
      publicSlug: 'milo-safe-card',
      isEnabled: false,
      publicNote: 'Публічна картка вимкнена.',
    ),
  ];
}
