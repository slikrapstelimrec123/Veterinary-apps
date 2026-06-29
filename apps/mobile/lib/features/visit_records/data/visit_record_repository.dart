import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../domain/visit_document.dart';
import '../domain/visit_record.dart';

class VisitRecordRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<VisitRecord>> getVisitRecordsForPet(String petId) async {
    if (_useMockData) {
      return MockData.visitRecords.where((record) => record.petId == petId).toList()
        ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    }

    final rows = await _client
        .from('visit_records')
        .select('*, clinics(name), doctors(full_name)')
        .eq('pet_id', petId)
        .eq('status', 'completed')
        .order('visit_date', ascending: false);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(VisitRecord.fromJson).toList();
  }

  Future<VisitRecord?> getVisitRecord(String id) async {
    if (_useMockData) {
      for (final record in MockData.visitRecords) {
        if (record.id == id) {
          return record;
        }
      }
      return null;
    }

    final row = await _client
        .from('visit_records')
        .select('*, clinics(name), doctors(full_name)')
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : VisitRecord.fromJson(row);
  }

  Future<List<VisitDocument>> getDocumentsForPet(String petId) async {
    if (_useMockData) {
      return MockData.documents.where((document) => document.petId == petId).toList();
    }

    final rows = await _client
        .from('visit_documents')
        .select('id,visit_record_id,pet_id,title,document_type,created_at')
        .eq('pet_id', petId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(VisitDocument.fromJson).toList();
  }

  Future<List<VisitDocument>> getDocumentsForVisit(String visitRecordId) async {
    if (_useMockData) {
      return MockData.documents.where((document) => document.visitRecordId == visitRecordId).toList();
    }

    final rows = await _client
        .from('visit_documents')
        .select('id,visit_record_id,pet_id,title,document_type,created_at')
        .eq('visit_record_id', visitRecordId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(VisitDocument.fromJson).toList();
  }
}
