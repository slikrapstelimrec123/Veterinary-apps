import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class DataExportResult {
  const DataExportResult({
    required this.file,
    required this.exportedFileCount,
    required this.warnings,
  });

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
          .select(
              'id,email,full_name,phone,city,role,created_at,updated_at')
          .eq('id', user.id)
          .maybeSingle(),
      warnings,
    );
    final pets = await _readRows(
      'Тварини',
      () => _client.from('pets').select('*').order('created_at'),
      warnings,
    );
    final visitRecords = await _readRows(
      'Записи про прийоми',
      () => _client
          .from('visit_records')
          .select(
              'id,pet_id,owner_id,visit_date,provider_name,reason,reason_for_visit,symptoms,diagnosis,procedures_performed,treatment_notes,prescribed_medications,recommendations,follow_up_at,next_visit_recommended,next_visit_date,status,created_at,updated_at')
          .order('visit_date'),
      warnings,
    );
    final visitDocuments = await _readRows(
      'Медичні документи',
      () => _client
          .from('visit_documents')
          .select('*')
          .eq('is_visible_to_owner', true)
          .order('created_at'),
      warnings,
    );
    final notifications = await _readRows(
      'Сповіщення',
      () => _client.from('notifications').select('*').order('created_at'),
      warnings,
    );
    final medications = await _readRows(
      'Препарати',
      () => _client.from('pet_medications').select('*').order('given_date'),
      warnings,
    );
    final feedings = await _readRows(
      'Харчування',
      () => _client.from('pet_feedings').select('*').order('start_date'),
      warnings,
    );
    final achievements = await _readRows(
      'Події',
      () => _client.from('pet_achievements').select('*').order('event_date'),
      warnings,
    );
    final announcements = await _readRows(
      'Оголошення',
      () => _client
          .from('announcements')
          .select('*')
          .eq('owner_id', user.id)
          .order('created_at'),
      warnings,
    );
    final transfers = await _readRows(
      'Передачі тварин',
      () => _client
          .from('pet_transfers')
          .select('*')
          .or('from_user_id.eq.${user.id},to_user_id.eq.${user.id}')
          .order('created_at'),
      warnings,
    );
    final preferences = await _readSingle(
      'Налаштування сповіщень',
      () async {
        final value =
            await _client.rpc('get_my_notification_preferences');
        return Map<String, dynamic>.from(value as Map);
      },
      warnings,
    );

    final exportData = <_ExportSection>[
      _ExportSection('Профіль', profile == null ? const [] : [profile]),
      _ExportSection('Тварини', pets),
      _ExportSection('Записи про прийоми', visitRecords),
      _ExportSection('Медичні документи', visitDocuments),
      _ExportSection('Препарати', medications),
      _ExportSection('Харчування', feedings),
      _ExportSection('Події', achievements),
      _ExportSection('Оголошення', announcements),
      _ExportSection('Передачі тварин', transfers),
      _ExportSection('Сповіщення', notifications),
      _ExportSection(
        'Налаштування сповіщень',
        preferences == null ? const [] : [preferences],
      ),
    ];

    final archive = Archive();
    final pdfBytes = await _createReadablePdf(exportData);
    archive.addFile(
      ArchiveFile('Lappo-data.pdf', pdfBytes.length, pdfBytes),
    );

    var exportedFileCount = 0;
    final usedNames = <String>{};
    for (final pet in pets) {
      final petName = _safeName(
        _displayValue(pet['name']).isEmpty
            ? 'tvaryna'
            : _displayValue(pet['name']),
      );
      exportedFileCount += await _addStorageFile(
        archive: archive,
        bucket: 'pet-documents',
        storagePath: pet['avatar_storage_path'] as String?,
        preferredName: '${petName}_foto',
        usedNames: usedNames,
        warnings: warnings,
      );
      exportedFileCount += await _addStorageFile(
        archive: archive,
        bucket: 'pet-documents',
        storagePath: pet['passport_storage_path'] as String?,
        preferredName: '${petName}_pasport',
        usedNames: usedNames,
        warnings: warnings,
      );
    }
    for (final document in visitDocuments) {
      final storagePath = document['storage_path'] as String?;
      final originalName = document['file_name'] as String?;
      exportedFileCount += await _addStorageFile(
        archive: archive,
        bucket: document['storage_bucket'] as String? ?? 'visit-documents',
        storagePath: storagePath,
        preferredName: originalName ?? 'medychnyi_dokument',
        usedNames: usedNames,
        warnings: warnings,
      );
    }
    for (final achievement in achievements) {
      final title = _safeName(
        _displayValue(achievement['title']).isEmpty
            ? 'podiia'
            : _displayValue(achievement['title']),
      );
      for (final entry in <MapEntry<String, String>>[
        const MapEntry('award_image_path', 'nahoroda'),
        const MapEntry('event_photo_path', 'foto'),
      ]) {
        exportedFileCount += await _addStorageFile(
          archive: archive,
          bucket: 'pet-documents',
          storagePath: achievement[entry.key] as String?,
          preferredName: '${title}_${entry.value}',
          usedNames: usedNames,
          warnings: warnings,
        );
      }
    }

    if (exportedFileCount == 0) {
      _addTextFile(
        archive,
        'documents/Файлів_немає.txt',
        'До цього експорту не додано жодного фото або документа.',
      );
    }

    final bytes = ZipEncoder().encode(archive);
    final directory = await getTemporaryDirectory();
    final timestamp =
        DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/lappo-export-$timestamp.zip');
    await file.writeAsBytes(bytes, flush: true);
    return DataExportResult(
      file: file,
      exportedFileCount: exportedFileCount,
      warnings: warnings,
    );
  }

  Future<List<int>> _createReadablePdf(
      List<_ExportSection> sections) async {
    final fontData =
        await rootBundle.load('assets/fonts/Montserrat-Variable.ttf');
    final font = pw.Font.ttf(fontData);
    final generatedAt = DateTime.now().toLocal();
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 36, 34, 34),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColor.fromInt(0xFFE5E1F3),
                    ),
                  ),
                ),
                child: pw.Text(
                  'Lappo - експорт даних',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFF6F5AE8),
                    fontSize: 10,
                  ),
                ),
              ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Сторінка ${context.pageNumber} з ${context.pagesCount}',
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF777386),
              fontSize: 9,
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Lappo',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF18213D),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Повний експорт даних',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF6F5AE8),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Створено ${_formatDateTime(generatedAt)}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF777386),
            ),
          ),
          pw.SizedBox(height: 18),
          ...sections.expand(_buildSection),
        ],
      ),
    );
    return document.save();
  }

  Iterable<pw.Widget> _buildSection(_ExportSection section) sync* {
    yield pw.Header(
      level: 1,
      text: section.title,
      textStyle: pw.TextStyle(
        fontSize: 17,
        fontWeight: pw.FontWeight.bold,
        color: const PdfColor.fromInt(0xFF18213D),
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            width: 1.2,
            color: PdfColor.fromInt(0xFFBEB4F4),
          ),
        ),
      ),
    );
    if (section.rows.isEmpty) {
      yield pw.Text(
        'Немає записів.',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColor.fromInt(0xFF777386),
        ),
      );
      yield pw.SizedBox(height: 10);
      return;
    }

    for (var index = 0; index < section.rows.length; index++) {
      final visibleEntries = section.rows[index].entries
          .where((entry) => !_isTechnicalField(entry.key))
          .where((entry) => _displayValue(entry.value).isNotEmpty)
          .toList(growable: false);
      yield pw.Text(
        section.rows.length == 1
            ? _recordTitle(section.rows[index], section.title)
            : '${index + 1}. ${_recordTitle(section.rows[index], section.title)}',
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF6F5AE8),
        ),
      );
      yield pw.SizedBox(height: 4);
      if (visibleEntries.isEmpty) {
        yield pw.Text('Додаткових даних немає.');
      } else {
        yield pw.Table(
          border: pw.TableBorder.all(
            color: const PdfColor.fromInt(0xFFE5E1F3),
            width: 0.6,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.1),
            1: pw.FlexColumnWidth(2),
          },
          children: [
            for (final entry in visibleEntries)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      _labelFor(entry.key),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF555166),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      _displayValue(entry.value),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFF18213D),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      }
      yield pw.SizedBox(height: 10);
    }
  }

  Future<Map<String, dynamic>?> _readSingle(
    String label,
    Future<Map<String, dynamic>?> Function() loader,
    List<String> warnings,
  ) async {
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
    List<String> warnings,
  ) async {
    try {
      return await loader();
    } catch (_) {
      warnings.add('$label не додано до експорту.');
      return const [];
    }
  }

  Future<int> _addStorageFile({
    required Archive archive,
    required String bucket,
    required String? storagePath,
    required String preferredName,
    required Set<String> usedNames,
    required List<String> warnings,
  }) async {
    if (storagePath == null || storagePath.isEmpty) return 0;
    try {
      final bytes = await _client.storage.from(bucket).download(storagePath);
      final extension = _extensionOf(storagePath);
      final base = _safeName(preferredName).replaceFirst(
        RegExp(r'\.[A-Za-z0-9]{1,8}$'),
        '',
      );
      var candidate = '$base$extension';
      var suffix = 2;
      while (usedNames.contains(candidate.toLowerCase())) {
        candidate = '${base}_$suffix$extension';
        suffix++;
      }
      usedNames.add(candidate.toLowerCase());
      archive.addFile(
        ArchiveFile('documents/$candidate', bytes.length, bytes),
      );
      return 1;
    } catch (_) {
      warnings.add(
        'Не вдалося додати файл ${_safeName(storagePath)}.',
      );
      return 0;
    }
  }

  void _addTextFile(Archive archive, String name, String value) {
    final bytes = utf8.encode(value);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  String _recordTitle(Map<String, dynamic> row, String fallback) {
    for (final key in const [
      'name',
      'title',
      'full_name',
      'breed',
      'provider_name',
      'reason',
      'file_name',
      'type',
    ]) {
      final value = _displayValue(row[key]);
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  bool _isTechnicalField(String key) {
    if (key == 'id' ||
        key.endsWith('_id') ||
        key.endsWith('_path') ||
        key == 'storage_bucket' ||
        key == 'created_at' ||
        key == 'updated_at' ||
        key == 'deleted_at') {
      return true;
    }
    return const {
      'raw_user_meta_data',
      'raw_app_meta_data',
      'is_visible_to_owner',
    }.contains(key);
  }

  String _displayValue(Object? value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Так' : 'Ні';
    if (value is DateTime) return _formatDateTime(value.toLocal());
    if (value is List) {
      return value
          .map(_displayValue)
          .where((item) => item.isNotEmpty)
          .join(', ');
    }
    if (value is Map) {
      return value.entries
          .where((entry) => !_isTechnicalField(entry.key.toString()))
          .map((entry) {
            final display = _displayValue(entry.value);
            return display.isEmpty
                ? ''
                : '${_labelFor(entry.key.toString())}: $display';
          })
          .where((item) => item.isNotEmpty)
          .join('; ');
    }
    final text = value.toString().trim();
    final parsed = DateTime.tryParse(text);
    if (parsed != null &&
        RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)) {
      return text.length <= 10
          ? _formatDate(parsed.toLocal())
          : _formatDateTime(parsed.toLocal());
    }
    return text;
  }

  String _labelFor(String key) => _fieldLabels[key] ?? _humanize(key);

  String _humanize(String key) {
    final words = key
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .join(' ');
    if (words.isEmpty) return key;
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.'
      '${value.year}';

  String _formatDateTime(DateTime value) =>
      '${_formatDate(value)} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _extensionOf(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final match = RegExp(r'(\.[A-Za-z0-9]{1,8})$').firstMatch(name);
    return match?.group(1)?.toLowerCase() ?? '';
  }

  String _safeName(String value) {
    final name = value.split(RegExp(r'[/\\]')).last.trim();
    final safe = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty ? 'document' : safe;
  }
}

class _ExportSection {
  const _ExportSection(this.title, this.rows);

  final String title;
  final List<Map<String, dynamic>> rows;
}

const _fieldLabels = <String, String>{
  'email': 'Електронна пошта',
  'full_name': 'Імʼя',
  'phone': 'Телефон',
  'city': 'Місто',
  'role': 'Тип профілю',
  'name': 'Імʼя',
  'species': 'Вид',
  'breed': 'Порода',
  'gender': 'Стать',
  'birth_date': 'Дата народження',
  'weight_kg': 'Вага, кг',
  'color': 'Колір',
  'microchip_number': 'Номер мікрочипа',
  'is_sterilized': 'Стерилізовано',
  'notes': 'Нотатки',
  'visit_date': 'Дата прийому',
  'provider_name': 'Місце або спеціаліст',
  'reason': 'Причина звернення',
  'reason_for_visit': 'Причина звернення',
  'symptoms': 'Симптоми',
  'diagnosis': 'Діагноз',
  'procedures_performed': 'Проведені процедури',
  'treatment_notes': 'Лікування',
  'prescribed_medications': 'Призначені препарати',
  'recommendations': 'Рекомендації',
  'follow_up_at': 'Повторний прийом',
  'next_visit_recommended': 'Рекомендовано повторний прийом',
  'next_visit_date': 'Дата повторного прийому',
  'status': 'Статус',
  'file_name': 'Назва файла',
  'document_type': 'Тип документа',
  'mime_type': 'Формат файла',
  'file_size': 'Розмір файла',
  'file_size_bytes': 'Розмір файла, байт',
  'given_date': 'Дата початку',
  'start_date': 'Дата початку',
  'end_date': 'Дата завершення',
  'medication_name': 'Назва препарату',
  'dosage': 'Дозування',
  'frequency': 'Періодичність',
  'food_name': 'Назва корму',
  'brand': 'Бренд',
  'amount': 'Кількість',
  'event_date': 'Дата події',
  'title': 'Назва',
  'description': 'Опис',
  'type': 'Тип',
  'price': 'Ціна',
  'location': 'Місто',
  'is_active': 'Активне',
  'message': 'Повідомлення',
  'read_at': 'Прочитано',
  'notifications_enabled': 'Сповіщення дозволені',
  'medication_reminders': 'Нагадування про препарати',
  'visit_reminders': 'Нагадування про прийоми',
};
