import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/visit_record_repository.dart';
import '../domain/visit_record.dart';
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
  late Future<List<VisitRecord>> recordsFuture = repository.getVisitRecordsForPet(widget.petId);

  void refresh() {
    setState(() => recordsFuture = repository.getVisitRecordsForPet(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VisitRecord>>(
      future: recordsFuture,
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];

        return AppScaffold(
          title: 'Treatment history',
          subtitle: widget.petName,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Unable to load treatment history.', onRetry: refresh)
            else if (records.isEmpty)
              const EmptyState(
                title: 'No treatment records yet',
                message: 'Records will appear here after a clinic adds them.',
                icon: Icons.history_outlined,
              )
            else
              ...records.map((record) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VisitRecordCard(record: record),
                  )),
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
    final date = record.visitDate.toIso8601String().split('T').first;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitRecordDetailsScreen(recordId: record.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(record.clinicName ?? 'Clinic not specified'),
              const SizedBox(height: 6),
              Text(record.reason ?? record.diagnosis ?? 'Visit record'),
              if (record.recommendations != null) ...[
                const SizedBox(height: 6),
                Text(record.recommendations!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Text('${record.documentCount} documents', style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

