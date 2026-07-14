import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataExportResult {
  const DataExportResult(
      {required this.file,
      required this.exportedFileCount,
      required this.warnings});

  final File file;
  final int exportedFileCount;
  final List<String> warnings;
}

class DataExportService {
  DataExportService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DataExportResult> createExport() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Authentication required');

    final warnings = <String>[];
    final profile = await _readSingle(
        'Профіль',
        () => _client
            .from('profiles')
            .select('id,email,full_name,phone,city,role,created_at,updated_at')
            .eq('id', user.id)
            .maybeSingle(),
        warnings);
    final pets = await _readRows('Тварини',
        () => _client.from('pets').select('*').order('created_at'), warnings);
    final appointments = await _readRows(
        'Записи на прийом',
        () => _client
            .from('appointments')
            .select(
                'id,clinic_id,doctor_id,service_id,pet_id,owner_id,starts_at,ends_at,status,price_amount,price_currency,owner_comment,cancelled_at,created_at,updated_at')
            .order('starts_at'),
        warnings);
    final visitRecords = await _readRows(
        'Медичні записи',
        () => _client
            .from('visit_records')
            .select(
                'id,appointment_id,clinic_id,doctor_id,pet_id,owner_id,visit_date,reason,reason_for_visit,symptoms,diagnosis,procedures_performed,treatment_notes,prescribed_medications,recommendations,follow_up_at,next_visit_recommended,next_visit_date,status,created_at,updated_at')
            .order('visit_date'),
        warnings);
    final visitDocuments = await _readRows(
        'Медичні документи',
        () => _client
            .from('visit_documents')
            .select('*')
            .eq('is_visible_to_owner', true)
            .order('created_at'),
        warnings);
    final notifications = await _readRows(
        'Сповіщення',
        () => _client.from('notifications').select('*').order('created_at'),
        warnings);
    final preferences = await _readSingle('Налаштування сповіщень', () async {
      final value = await _client.rpc('get_my_notification_preferences');
      return Map<String, dynamic>.from(value as Map);
    }, warnings);

    final archive = Archive();
    _addTextFile(
        archive,
        'lappo-data.json',
        const JsonEncoder.withIndent('  ').convert({
          'exported_at': DateTime.now().toUtc().toIso8601String(),
          'format_version': 1,
          'profile': profile,
          'pets': pets,
          'appointments': appointments,
          'visit_records': visitRecords,
          'visit_documents': visitDocuments,
          'notifications': notifications,
          'notification_preferences': preferences,
        }));
    _addTextFile(archive, 'README.txt',
        'Експорт Lappo містить приватні дані профілю, тварин та медичні документи, доступні вашому акаунту. Зберігайте цей архів у безпечному місці та не надсилайте його стороннім особам.');

    var exportedFileCount = 0;
    for (final pet in pets) {
      exportedFileCount += await _addStorageFile(
          archive: archive,
          bucket: 'pet-documents',
          storagePath: pet['avatar_storage_path'] as String?,
          archivePath: 'files/pets/${pet['id']}/avatar',
          warnings: warnings);
      exportedFileCount += await _addStorageFile(
          archive: archive,
          bucket: 'pet-documents',
          storagePath: pet['passport_storage_path'] as String?,
          archivePath: 'files/pets/${pet['id']}/passport',
          warnings: warnings);
    }
    for (final document in visitDocuments) {
      final storagePath = document['storage_path'] as String?;
      final originalName = document['file_name'] as String?;
      exportedFileCount += await _addStorageFile(
        archive: archive,
        bucket: document['storage_bucket'] as String? ?? 'visit-documents',
        storagePath: storagePath,
        archivePath:
            'files/medical/${document['id']}_${_safeName(originalName ?? storagePath ?? 'document')}',
        warnings: warnings,
      );
    }

    final bytes = ZipEncoder().encode(archive);
    final directory = await getTemporaryDirectory();
    final timestamp =
        DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/lappo-export-$timestamp.zip');
    await file.writeAsBytes(bytes, flush: true);
    return DataExportResult(
        file: file, exportedFileCount: exportedFileCount, warnings: warnings);
  }

  Future<Map<String, dynamic>?> _readSingle(
      String label,
      Future<Map<String, dynamic>?> Function() loader,
      List<String> warnings) async {
    try {
      return await loader();
    } catch (_) {
      warnings.add('$label не додано до експорту.');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _readRows(
      String label,
      Future<List<Map<String, dynamic>>> Function() loader,
      List<String> warnings) async {
    try {
      return await loader();
    } catch (_) {
      warnings.add('$label не додано до експорту.');
      return const [];
    }
  }

  Future<int> _addStorageFile(
      {required Archive archive,
      required String bucket,
      required String? storagePath,
      required String archivePath,
      required List<String> warnings}) async {
    if (storagePath == null || storagePath.isEmpty) return 0;
    try {
      final bytes = await _client.storage.from(bucket).download(storagePath);
      var targetPath = archivePath;
      final sourceName = _safeName(storagePath);
      if (!targetPath.split('/').last.contains('.') &&
          sourceName.contains('.')) {
        targetPath = '$targetPath.${sourceName.split('.').last}';
      }
      archive.addFile(ArchiveFile(_safePath(targetPath), bytes.length, bytes));
      return 1;
    } catch (_) {
      warnings.add('Не вдалося додати файл ${_safeName(storagePath)}.');
      return 0;
    }
  }

  void _addTextFile(Archive archive, String name, String value) {
    final bytes = utf8.encode(value);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  String _safeName(String value) {
    final name = value.split(RegExp(r'[/\\]')).last;
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _safePath(String value) => value
      .split('/')
      .where((part) => part.isNotEmpty && part != '.' && part != '..')
      .map(_safeName)
      .join('/');
}
