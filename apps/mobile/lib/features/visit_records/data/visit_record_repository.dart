import 'dart:io';

import 'package:path/path.dart' as p;
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
      return MockData.visitRecords.where((record) => record.petId == petId && record.status == 'published').toList()
        ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    }

    final rows = await _client
        .from('visit_records')
        .select('*')
        .eq('pet_id', petId)
        .order('visit_date', ascending: false);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(VisitRecord.fromJson).toList();
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
        .select('*')
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : VisitRecord.fromJson(row);
  }

  Future<VisitRecord?> getVisitRecordForAppointment(String appointmentId) async {
    if (_useMockData) {
      for (final record in MockData.visitRecords) {
        if (record.appointmentId == appointmentId) return record;
      }
      return null;
    }

    final row = await _client
        .from('visit_records')
        .select('*')
        .eq('appointment_id', appointmentId)
        .maybeSingle();

    return row == null ? null : VisitRecord.fromJson(row);
  }

  Future<List<VisitDocument>> getDocumentsForPet(String petId) async {
    if (_useMockData) {
      return MockData.documents.where((document) => document.petId == petId && document.isVisibleToOwner).toList();
    }

    final rows = await _client
        .from('visit_documents')
        .select('id,visit_record_id,pet_id,title,document_type,file_name,file_type,file_size,description,storage_bucket,storage_path,is_visible_to_owner,created_at')
        .eq('pet_id', petId)
        .eq('is_visible_to_owner', true)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(VisitDocument.fromJson).toList();
  }

  Future<List<VisitDocument>> getDocumentsForVisit(String visitRecordId) async {
    if (_useMockData) {
      return MockData.documents.where((document) => document.visitRecordId == visitRecordId && document.isVisibleToOwner).toList();
    }

    final rows = await _client
        .from('visit_documents')
        .select('id,visit_record_id,pet_id,title,document_type,file_name,file_type,file_size,description,storage_bucket,storage_path,is_visible_to_owner,created_at')
        .eq('visit_record_id', visitRecordId)
        .eq('is_visible_to_owner', true)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().map(VisitDocument.fromJson).toList();
  }

  Future<String?> getSignedDocumentUrl(VisitDocument document) async {
    if (_useMockData) {
      return null;
    }

    if (document.storagePath == null || !document.isVisibleToOwner) {
      return null;
    }

    return _client.storage.from(document.storageBucket).createSignedUrl(document.storagePath!, 60);
  }

  Future<VisitDocument> uploadDocument({
    required String visitRecordId,
    required String petId,
    required File file,
    required String title,
    required String documentType,
  }) async {
    final fileName = p.basename(file.path);
    final storagePath = '$petId/$visitRecordId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final bytes = await file.readAsBytes();

    await _client.storage.from('visit-documents').uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: _mimeType(fileName), upsert: false),
    );

    final fileSize = bytes.length;
    final row = await _client.from('visit_documents').insert({
      'visit_record_id': visitRecordId,
      'pet_id': petId,
      'title': title,
      'document_type': documentType,
      'file_name': fileName,
      'file_type': _mimeType(fileName),
      'file_size': fileSize,
      'storage_bucket': 'visit-documents',
      'storage_path': storagePath,
      'is_visible_to_owner': true,
    }).select().single();

    return VisitDocument.fromJson(row);
  }

  String _mimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return switch (ext) {
      '.pdf' => 'application/pdf',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.doc' => 'application/msword',
      '.docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }
}
