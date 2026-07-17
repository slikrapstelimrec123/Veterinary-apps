import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/visit_record_repository.dart';
import '../domain/visit_document.dart';
import '../domain/visit_record.dart';

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

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.repository});

  final VisitDocument document;
  final VisitRecordRepository repository;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(document.title),
        subtitle: Text(
          '${document.type} · ${document.fileSizeLabel} · '
          '${document.createdAt.toIso8601String().split('T').first}',
        ),
        trailing: const Icon(Icons.lock_outline),
        onTap: () async {
          final url = await repository.getSignedDocumentUrl(document);
          if (!context.mounted) return;
          if (url == null ||
              !await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              )) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не вдалося відкрити файл.')),
            );
          }
        },
      ),
    );
  }
}
