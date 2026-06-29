import 'package:flutter/material.dart';

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
  State<VisitRecordDetailsScreen> createState() => _VisitRecordDetailsScreenState();
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
          title: 'Visit details',
          subtitle: record?.clinicName ?? 'Medical record',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Unable to load visit details.', onRetry: refresh)
            else if (record == null)
              const EmptyState(title: 'Visit not found', message: 'This treatment record is not available.', icon: Icons.search_off_outlined)
            else ...[
              _RecordSection(title: 'Visit date', body: record.visitDate.toIso8601String().split('T').first),
              _RecordSection(title: 'Clinic', body: record.clinicName ?? 'Not specified'),
              _RecordSection(title: 'Doctor', body: record.doctorName ?? 'Not specified'),
              _RecordSection(title: 'Reason', body: record.reason ?? 'Not specified'),
              _RecordSection(title: 'Diagnosis', body: record.diagnosis ?? 'Not specified'),
              _RecordSection(title: 'Treatment', body: record.treatmentNotes ?? 'No treatment notes added.'),
              _RecordSection(title: 'Recommendations', body: record.recommendations ?? 'No recommendations added.'),
              _RecordSection(
                title: 'Next visit',
                body: record.followUpAt?.toIso8601String().split('T').first ?? 'No follow-up date.',
              ),
              const SizedBox(height: 8),
              Text('Documents', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (documents.isEmpty)
                const EmptyState(
                  title: 'No documents attached',
                  message: 'No documents attached to this visit.',
                  icon: Icons.attach_file_outlined,
                )
              else
                ...documents.map((document) => _DocumentTile(document: document)),
            ],
          ],
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
  const _DocumentTile({required this.document});

  final VisitDocument document;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(document.title),
        subtitle: Text('${document.type} · ${document.createdAt.toIso8601String().split('T').first}'),
        trailing: const Text('Private'),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Secure document viewing will be connected after private file access is implemented.')),
          );
        },
      ),
    );
  }
}

