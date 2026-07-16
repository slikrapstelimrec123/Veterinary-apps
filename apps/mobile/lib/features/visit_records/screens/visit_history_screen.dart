import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/visit_record_repository.dart';
import '../domain/visit_record.dart';
import 'add_visit_record_screen.dart';
import 'visit_record_details_screen.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  final String petId;
  final String petName;

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  final repository = VisitRecordRepository();
  late Future<List<VisitRecord>> recordsFuture =
      repository.getVisitRecordsForPet(widget.petId);

  void refresh() {
    setState(
        () => recordsFuture = repository.getVisitRecordsForPet(widget.petId));
  }

  Future<void> _addRecord() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          AddVisitRecordScreen(petId: widget.petId, petName: widget.petName),
    ));
    if (result != null) {
      refresh();
      if (result is String && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VisitRecord>>(
      future: recordsFuture,
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];

        return AppScaffold(
          title: 'Історія прийомів',
          subtitle: widget.petName,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Додати прийом',
              onPressed: _addRecord,
            ),
          ],
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити історію прийомів.',
                  onRetry: refresh)
            else if (records.isEmpty)
              EmptyState(
                title: 'Записів про прийоми ще немає',
                message:
                    'Додайте перший запис про прийом, лікування або огляд самостійно.',
                icon: Icons.history_outlined,
                action: FilledButton(
                  onPressed: _addRecord,
                  child: const Text('Додати прийом'),
                ),
              )
            else ...[
              ...records.map((record) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VisitRecordCard(record: record),
                  )),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _addRecord,
                icon: const Icon(Icons.add),
                label: const Text('Додати запис про прийом'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VisitRecordCard extends StatelessWidget {
  const _VisitRecordCard({required this.record});

  final VisitRecord record;

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(record.visitDate);
    final isSelfReported = record.status == 'self_reported';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VisitRecordDetailsScreen(recordId: record.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(date,
                          style: Theme.of(context).textTheme.titleMedium)),
                  if (isSelfReported)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Власний запис',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(record.clinicName ?? 'Клініку не вказано'),
              const SizedBox(height: 4),
              Text(record.reason ?? record.diagnosis ?? 'Запис прийому'),
              if (record.treatmentNotes != null) ...[
                const SizedBox(height: 4),
                Text(record.treatmentNotes!,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (record.documentCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 14),
                    const SizedBox(width: 4),
                    Text('Документів: ${record.documentCount}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
