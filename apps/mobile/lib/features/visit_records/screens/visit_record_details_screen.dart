import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/screens/leave_review_screen.dart';
import '../data/visit_record_repository.dart';
import '../domain/visit_document.dart';
import '../domain/visit_record.dart';

class VisitRecordDetailsScreen extends StatefulWidget {
  const VisitRecordDetailsScreen({super.key, required this.recordId});

  final String recordId;

  @override
  State<VisitRecordDetailsScreen> createState() => _VisitRecordDetailsScreenState();
}

class _VisitRecordDetailsScreenState extends State<VisitRecordDetailsScreen> {
  final repository = VisitRecordRepository();
  final reviewRepository = ReviewRepository();
  late Future<_VisitDetailsData> future = load();

  Future<_VisitDetailsData> load() async {
    final record = await repository.getVisitRecord(widget.recordId);
    final documents = await repository.getDocumentsForVisit(widget.recordId);
    return _VisitDetailsData(record: record, documents: documents);
  }

  void refresh() {
    setState(() => future = load());
  }

  void _showUploadSheet(String visitRecordId, String petId) {
    final titleController = TextEditingController();
    String selectedType = 'analysis';

    const types = {
      'analysis': 'Аналіз',
      'xray': 'Рентген / УЗД',
      'prescription': 'Рецепт',
      'vaccination': 'Вакцинація',
      'other': 'Інше',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Додати документ', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Назва документа',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип документа',
                  border: OutlineInputBorder(),
                ),
                items: types.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setSheet(() => selectedType = v ?? selectedType),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Обрати файл'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Завантаження файлів буде доступне у наступному оновленні.')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VisitDetailsData>(
      future: future,
      builder: (context, snapshot) {
        final record = snapshot.data?.record;
        final documents = snapshot.data?.documents ?? [];

        return AppScaffold(
          title: 'Деталі візиту',
          subtitle: record?.clinicName ?? 'Медичний запис',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити деталі візиту.', onRetry: refresh)
            else if (record == null)
              const EmptyState(title: 'Візит не знайдено', message: 'Цей запис лікування недоступний.', icon: Icons.search_off_outlined)
            else ...[
              _RecordSection(title: 'Дата візиту', body: record.visitDate.toIso8601String().split('T').first),
              _RecordSection(title: 'Клініка', body: record.clinicName ?? 'Не вказано'),
              _RecordSection(title: 'Лікар', body: record.doctorName ?? 'Не вказано'),
              _RecordSection(title: 'Причина', body: record.reason ?? 'Не вказано'),
              _RecordSection(title: 'Симптоми', body: record.symptoms ?? 'Не вказано'),
              _RecordSection(title: 'Діагноз', body: record.diagnosis ?? 'Не вказано'),
              _RecordSection(title: 'Процедури', body: record.proceduresPerformed ?? 'Процедури не додано.'),
              _RecordSection(title: 'Лікування', body: record.treatmentNotes ?? 'Нотатки про лікування не додано.'),
              _RecordSection(title: 'Препарати', body: record.prescribedMedications ?? 'Препарати не додано.'),
              _RecordSection(title: 'Рекомендації', body: record.recommendations ?? 'Рекомендації не додано.'),
              _RecordSection(title: 'Наступний візит', body: _nextVisitLabel(record)),
              if (record.appointmentId != null && record.clinicId != null)
                _VisitReviewAction(record: record, repository: reviewRepository, onChanged: refresh),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Документи', style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: () => _showUploadSheet(record.id, record.petId),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Додати'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (documents.isEmpty)
                const EmptyState(
                  title: 'Документи не прикріплено',
                  message: 'До цього візиту документи не прикріплено.',
                  icon: Icons.attach_file_outlined,
                )
              else
                ...documents.map((doc) => _DocumentTile(document: doc, repository: repository)),
            ],
          ],
        );
      },
    );
  }

  String _nextVisitLabel(VisitRecord record) {
    if (!record.nextVisitRecommended) return 'Дату повторного візиту не вказано.';
    return record.nextVisitDate?.toIso8601String().split('T').first ?? 'Рекомендовано, але дату не вказано.';
  }
}

class _VisitReviewAction extends StatelessWidget {
  const _VisitReviewAction({required this.record, required this.repository, required this.onChanged});

  final VisitRecord record;
  final ReviewRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repository.getReviewForAppointment(record.appointmentId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        if (snapshot.data != null) {
          return const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Цей візит уже оцінено.')));
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LeaveReviewScreen(
                  clinicId: record.clinicId!,
                  clinicName: record.clinicName ?? 'Клініка',
                  appointmentId: record.appointmentId!,
                  visitRecordId: record.id,
                  petId: record.petId,
                  doctorId: record.doctorId,
                  doctorName: record.doctorName,
                ),
              ));
              onChanged();
            },
            icon: const Icon(Icons.star_border),
            label: const Text('Залишити відгук'),
          ),
        );
      },
    );
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
        subtitle: Text('${document.type} · ${document.fileSizeLabel} · ${document.createdAt.toIso8601String().split('T').first}'),
        trailing: const Icon(Icons.lock_outline),
        onTap: () async {
          final url = await repository.getSignedDocumentUrl(document);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(url == null ? 'Перегляд файлу поки недоступний.' : 'Посилання створено.')),
          );
        },
      ),
    );
  }
}
