import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/visit_record_repository.dart';
import '../domain/visit_document.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  final String petId;
  final String petName;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final repository = VisitRecordRepository();
  late Future<List<VisitDocument>> documentsFuture = repository.getDocumentsForPet(widget.petId);

  void refresh() {
    setState(() => documentsFuture = repository.getDocumentsForPet(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VisitDocument>>(
      future: documentsFuture,
      builder: (context, snapshot) {
        final documents = snapshot.data ?? [];

        return AppScaffold(
          title: 'Documents',
          subtitle: widget.petName,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Unable to load documents.', onRetry: refresh)
            else if (documents.isEmpty)
              const EmptyState(
                title: 'No documents yet',
                message: 'Medical documents uploaded by clinics will appear here.',
                icon: Icons.folder_open_outlined,
              )
            else
              ...documents.map((document) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(document.title),
                      subtitle: Text('${document.type} · ${document.createdAt.toIso8601String().split('T').first}'),
                      trailing: const Text('Private'),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

