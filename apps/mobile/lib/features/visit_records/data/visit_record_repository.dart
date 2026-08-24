import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/data/app_data_events.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../shared/data/mock_data.dart';
import '../../pets/data/pet_repository.dart';
import '../domain/visit_document.dart';
import '../domain/visit_record.dart';

class VisitRecordRepository {
  static const _ownerSafeColumns = 'id,pet_id,created_by,visit_date,'
      'reason,diagnosis,treatment_notes,recommendations,follow_up_at,status,'
      'created_at,updated_at,owner_id,reason_for_visit,symptoms,'
      'procedures_performed,prescribed_medications,next_visit_recommended,'
      'next_visit_date,provider_name';

  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<VisitRecord>> getVisitRecordsForPet(String petId) async {
    if (_useMockData) {
      return MockData.visitRecords
          .where(
              (record) => record.petId == petId && record.status == 'published')
          .toList()
        ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    }

    final rows = await _client
        .from('visit_records')
        .select(_ownerSafeColumns)
        .eq('pet_id', petId)
        .order('visit_date', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(VisitRecord.fromJson)
        .toList();
  }

  Future<VisitRecord?> getVisitRecord(String id) async {
    if (_useMockData) {
      for (final record in MockData.visitRecords) {
        if (record.id == id) return record;
      }
      return null;
    }

    final row = await _client
        .from('visit_records')
        .select(_ownerSafeColumns)
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : VisitRecord.fromJson(row);
  }

  Future<VisitRecord> createSelfReportedVisitRecord({
    required String petId,
    required DateTime visitDate,
    required String reason,
    String? providerName,
    String? symptoms,
    String? diagnosis,
    String? treatmentNotes,
    String? prescribedMedications,
    String? recommendations,
    bool nextVisitRecommended = false,
    DateTime? nextVisitDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Authentication required');
    }

    final row = await _client
        .from('visit_records')
        .insert({
          'pet_id': petId,
          'owner_id': userId,
          'created_by': userId,
          'visit_date': visitDate.toIso8601String().split('T').first,
          'reason': reason.trim(),
          'reason_for_visit': reason.trim(),
          'provider_name': _nullable(providerName),
          'symptoms': _nullable(symptoms),
          'diagnosis': _nullable(diagnosis),
          'treatment_notes': _nullable(treatmentNotes),
          'prescribed_medications': _nullable(prescribedMedications),
          'recommendations': _nullable(recommendations),
          'next_visit_recommended': nextVisitRecommended,
          'next_visit_date': nextVisitRecommended && nextVisitDate != null
              ? nextVisitDate.toIso8601String().split('T').first
              : null,
          'status': 'self_reported',
        })
        .select(_ownerSafeColumns)
        .single();

    final saved = VisitRecord.fromJson(row);
    AppDataEvents.notifyChanged();
    final reminderDate = saved.nextVisitDate;
    if (saved.nextVisitRecommended && reminderDate != null) {
      try {
        final pet = await PetRepository().getPet(petId);
        await LocalNotificationService.instance.scheduleVisitReminder(
          visitRecordId: saved.id,
          petName: pet?.name ?? 'Тварина',
          dueDate: reminderDate,
        );
      } catch (_) {
        // The medical record remains saved even if scheduling is unavailable.
      }
    }
    return saved;
  }

  Future<VisitRecord> updateSelfReportedVisitRecord({
    required String id,
    required String petId,
    required DateTime visitDate,
    required String reason,
    String? providerName,
    String? symptoms,
    String? diagnosis,
    String? treatmentNotes,
    String? prescribedMedications,
    String? recommendations,
    bool nextVisitRecommended = false,
    DateTime? nextVisitDate,
  }) async {
    if (_useMockData) {
      final index =
          MockData.visitRecords.indexWhere((record) => record.id == id);
      if (index == -1) throw StateError('Visit record not found');
      final current = MockData.visitRecords[index];
      final updated = VisitRecord(
        id: id,
        petId: petId,
        visitDate: visitDate,
        providerName: _nullable(providerName),
        reason: reason.trim(),
        symptoms: _nullable(symptoms),
        diagnosis: _nullable(diagnosis),
        proceduresPerformed: current.proceduresPerformed,
        treatmentNotes: _nullable(treatmentNotes),
        prescribedMedications: _nullable(prescribedMedications),
        recommendations: _nullable(recommendations),
        nextVisitRecommended: nextVisitRecommended,
        nextVisitDate: nextVisitRecommended ? nextVisitDate : null,
        status: current.status,
        documentCount: current.documentCount,
      );
      MockData.visitRecords[index] = updated;
      AppDataEvents.notifyChanged();
      return updated;
    }
    final row = await _client
        .from('visit_records')
        .update({
          'visit_date': visitDate.toIso8601String().split('T').first,
          'reason': reason.trim(),
          'reason_for_visit': reason.trim(),
          'provider_name': _nullable(providerName),
          'symptoms': _nullable(symptoms),
          'diagnosis': _nullable(diagnosis),
          'treatment_notes': _nullable(treatmentNotes),
          'prescribed_medications': _nullable(prescribedMedications),
          'recommendations': _nullable(recommendations),
          'next_visit_recommended': nextVisitRecommended,
          'next_visit_date': nextVisitRecommended && nextVisitDate != null
              ? nextVisitDate.toIso8601String().split('T').first
              : null,
        })
        .eq('id', id)
        .eq('pet_id', petId)
        .eq('status', 'self_reported')
        .select(_ownerSafeColumns)
        .single();

    final saved = VisitRecord.fromJson(row);
    await _syncVisitReminder(saved);
    AppDataEvents.notifyChanged();
    return saved;
  }

  Future<void> deleteSelfReportedVisitRecord({
    required String id,
    required String petId,
  }) async {
    if (_useMockData) {
      MockData.visitRecords.removeWhere((record) => record.id == id);
      AppDataEvents.notifyChanged();
      return;
    }
    final documents = await _client
        .from('visit_documents')
        .select('storage_path')
        .eq('visit_record_id', id);
    await _client
        .from('visit_records')
        .delete()
        .eq('id', id)
        .eq('pet_id', petId)
        .eq('status', 'self_reported');

    final storagePaths = (documents as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((document) => document['storage_path'] as String?)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList();
    if (storagePaths.isNotEmpty) {
      try {
        await _client.storage.from('visit-documents').remove(storagePaths);
      } catch (_) {
        // Database references are already removed; storage cleanup can retry.
      }
    }
    try {
      await LocalNotificationService.instance.cancelVisitReminder(id);
    } catch (_) {
      // The database deletion remains successful if local cleanup is blocked.
    }
    AppDataEvents.notifyChanged();
  }

  Future<void> _syncVisitReminder(VisitRecord record) async {
    try {
      await LocalNotificationService.instance.cancelVisitReminder(record.id);
      if (record.nextVisitRecommended && record.nextVisitDate != null) {
        final pet = await PetRepository().getPet(record.petId);
        await LocalNotificationService.instance.scheduleVisitReminder(
          visitRecordId: record.id,
          petName: pet?.name ?? 'Тварина',
          dueDate: record.nextVisitDate!,
        );
      }
    } catch (_) {
      // The medical record remains updated if local scheduling is unavailable.
    }
  }

  Future<VisitDocument> uploadVisitImage({
    required String visitRecordId,
    required String petId,
    required File file,
    String documentType = 'photo',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Authentication required');
    }

    final sourceName = file.path.split(RegExp(r'[/\\]')).last;
    final extension = sourceName.contains('.')
        ? sourceName.split('.').last.toLowerCase()
        : 'jpg';
    final normalizedExtension = extension == 'jpeg' ? 'jpg' : extension;
    final mimeType = switch (normalizedExtension) {
      'png' => 'image/png',
      'heic' => 'image/heic',
      'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
    final storagePath =
        '$userId/$petId/$visitRecordId/${DateTime.now().microsecondsSinceEpoch}.$normalizedExtension';
    final fileSize = await file.length();

    await _client.storage.from('visit-documents').upload(
          storagePath,
          file,
          fileOptions: FileOptions(contentType: mimeType),
        );

    try {
      final documentId = await _client.rpc(
        'create_owner_visit_document',
        params: {
          'p_visit_record_id': visitRecordId,
          'p_pet_id': petId,
          'p_title': sourceName,
          'p_document_type': documentType,
          'p_storage_path': storagePath,
          'p_mime_type': mimeType,
          'p_file_size': fileSize,
          'p_file_name': sourceName,
        },
      ) as String;
      final row = await _client
          .from('visit_documents')
          .select(
              'id,visit_record_id,pet_id,title,document_type,file_name,file_type,file_size,description,storage_bucket,storage_path,is_visible_to_owner,created_at')
          .eq('id', documentId)
          .single();
      AppDataEvents.notifyChanged();
      return VisitDocument.fromJson(row);
    } catch (_) {
      try {
        await _client.storage.from('visit-documents').remove([storagePath]);
      } catch (_) {
        // The orphaned private file is inaccessible and can be cleaned later.
      }
      rethrow;
    }
  }

  String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<List<VisitDocument>> getDocumentsForPet(String petId) async {
    if (_useMockData) {
      return MockData.documents
          .where((document) =>
              document.petId == petId && document.isVisibleToOwner)
          .toList();
    }

    final rows = await _client
        .from('visit_documents')
        .select(
            'id,visit_record_id,pet_id,title,document_type,file_name,file_type,file_size,description,storage_bucket,storage_path,is_visible_to_owner,created_at')
        .eq('pet_id', petId)
        .eq('is_visible_to_owner', true)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(VisitDocument.fromJson)
        .toList();
  }

  Future<List<VisitDocument>> getDocumentsForVisit(String visitRecordId) async {
    if (_useMockData) {
      return MockData.documents
          .where((document) =>
              document.visitRecordId == visitRecordId &&
              document.isVisibleToOwner)
          .toList();
    }

    final rows = await _client
        .from('visit_documents')
        .select(
            'id,visit_record_id,pet_id,title,document_type,file_name,file_type,file_size,description,storage_bucket,storage_path,is_visible_to_owner,created_at')
        .eq('visit_record_id', visitRecordId)
        .eq('is_visible_to_owner', true)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(VisitDocument.fromJson)
        .toList();
  }

  Future<String?> getSignedDocumentUrl(VisitDocument document) async {
    if (_useMockData) {
      return null;
    }

    if (document.storagePath == null || !document.isVisibleToOwner) {
      return null;
    }

    return _client.storage
        .from(document.storageBucket)
        .createSignedUrl(document.storagePath!, 60);
  }

  Future<Uint8List?> downloadDocument(VisitDocument document) async {
    if (_useMockData ||
        document.storagePath == null ||
        !document.isVisibleToOwner) {
      return null;
    }

    return _client.storage
        .from(document.storageBucket)
        .download(document.storagePath!);
  }
}
