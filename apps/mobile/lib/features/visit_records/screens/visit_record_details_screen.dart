import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/visit_record_repository.dart';
import '../domain/visit_document.dart';
import '../domain/visit_record.dart';
import 'documents_screen.dart';

class VisitRecordDetailsScreen extends StatefulWidget {
  const VisitRecordDetailsScreen({super.key, required this.recordId});

  final String recordId;

  @override
  State<VisitRecordDetailsScreen> createState() =>
      _VisitRecordDetailsScreenState();
}

class _VisitRecordDetailsScreenState extends State<VisitRecordDetailsScreen> {
  final repository = VisitRecordRepository();
  late Future<_VisitDetailsData> future = load();

  Future<_VisitDetailsData> load() async {
    final record = await repository.getVisitRecord(widget.recordId);
    final documents = await repository.getDocumentsForVisit(widget.recordId);
    return _VisitDetailsData(record: record, documents: documents);
  }

  void refresh() {
    setState(() => future = load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VisitDetailsData>(
      future: future,
      builder: (context, snapshot) {
        final record = snapshot.data?.record;
        final documents = snapshot.data?.documents ?? [];

        return AppScaffold(
          title: 'Деталі прийому',
          subtitle: record?.providerName ?? 'Власний медичний запис',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                message: 'Не вдалося завантажити деталі прийому.',
                onRetry: refresh,
              )
            else if (record == null)
              const EmptyState(
                title: 'Запис не знайдено',
                message: 'Цей запис медичної історії недоступний.',
                icon: Icons.search_off_outlined,
              )
            else ...[
              _RecordSection(
                title: 'Дата прийому',
                body: record.visitDate.toIso8601String().split('T').first,
              ),
              if (record.providerName != null)
                _RecordSection(
                  title: 'Місце або фахівець',
                  body: record.providerName!,
                ),
              _RecordSection(
                title: 'Причина',
                body: record.reason ?? 'Не вказано',
              ),
              _RecordSection(
                title: 'Симптоми',
                body: record.symptoms ?? 'Не вказано',
              ),
              _RecordSection(
                title: 'Діагноз',
                body: record.diagnosis ?? 'Не вказано',
              ),
              _RecordSection(
                title: 'Процедури',
                body: record.proceduresPerformed ?? 'Процедури не додано.',
              ),
              _RecordSection(
                title: 'Лікування',
                body:
                    record.treatmentNotes ?? 'Нотатки про лікування не додано.',
              ),
              _RecordSection(
                title: 'Препарати',
                body: record.prescribedMedications ?? 'Препарати не додано.',
              ),
              _RecordSection(
                title: 'Рекомендації',
                body: record.recommendations ?? 'Рекомендації не додано.',
              ),
              _RecordSection(
                title: 'Наступний прийом',
                body: _nextVisitLabel(record),
              ),
              const SizedBox(height: 8),
              Text(
                'Документи',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (documents.isEmpty)
                const EmptyState(
                  title: 'Документи не прикріплено',
                  message: 'До цього запису документи не прикріплено.',
                  icon: Icons.attach_file_outlined,
                )
              else
                ...documents.map(
                  (document) => _DocumentTile(
                    document: document,
                    repository: repository,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  String _nextVisitLabel(VisitRecord record) {
    if (!record.nextVisitRecommended) {
      return 'Дату наступного прийому не вказано.';
    }
    return record.nextVisitDate?.toIso8601String().split('T').first ??
        'Наступний прийом рекомендовано, але дату не вказано.';
  }
}

class _VisitDetailsData {
  const _VisitDetailsData({required this.record, required this.documents});

  final VisitRecord? record;
  final List<VisitDocument> documents;
}

class _RecordSection extends StatelessWidget {
  const _RecordSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(body),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentTile extends StatefulWidget {
  const _DocumentTile({required this.document, required this.repository});

  final VisitDocument document;
  final VisitRecordRepository repository;

  @override
  State<_DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends State<_DocumentTile> {
  bool _busy = false;

  Future<void> _view() async {
    setState(() => _busy = true);
    try {
      final bytes = await widget.repository.downloadDocument(widget.document);
      if (bytes == null) throw StateError('OPEN_DOCUMENT_FAILED');
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DocumentViewerScreen(
          title: widget.document.title,
          fileName: widget.document.fileName ?? widget.document.title,
          bytes: bytes,
        ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося відкрити файл.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final bytes =
          await widget.repository.downloadDocument(widget.document);
      if (bytes == null) throw StateError('DOWNLOAD_DOCUMENT_FAILED');
      final directory = await getTemporaryDirectory();
      final fileName = _safeFileName(
        widget.document.fileName ?? widget.document.title,
      );
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.document.title,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося завантажити файл.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return normalized.isEmpty ? 'document' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(widget.document.title),
              subtitle: Text(
                '${widget.document.type} · ${widget.document.fileSizeLabel} · '
                '${widget.document.createdAt.toIso8601String().split('T').first}',
              ),
              trailing: const Icon(Icons.lock_outline),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _view,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Переглянути'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _download,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Завантажити'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
