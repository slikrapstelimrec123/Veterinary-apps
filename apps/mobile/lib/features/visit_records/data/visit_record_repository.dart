import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
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

    return VisitRecord.fromJson(row);
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
}
