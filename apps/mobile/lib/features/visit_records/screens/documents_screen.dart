import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late Future<List<VisitDocument>> documentsFuture =
      repository.getDocumentsForPet(widget.petId);

  void refresh() {
    setState(
        () => documentsFuture = repository.getDocumentsForPet(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VisitDocument>>(
      future: documentsFuture,
      builder: (context, snapshot) {
        final documents = snapshot.data ?? [];

        return AppScaffold(
          title: 'Документи',
          subtitle: widget.petName,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити документи.',
                  onRetry: refresh)
            else if (documents.isEmpty)
              const EmptyState(
                title: 'Документів ще немає',
                message: "Медичні документи з’являться тут.",
                icon: Icons.folder_open_outlined,
              )
            else
              ...documents.map((document) =>
                  _DocumentTile(document: document, repository: repository)),
          ],
        );
      },
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
            '${document.type} - ${document.fileSizeLabel} - ${document.createdAt.toIso8601String().split('T').first}'),
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
              const SnackBar(content: Text('Не вдалося відкрити документ.')),
            );
          }
        },
      ),
    );
  }
}
