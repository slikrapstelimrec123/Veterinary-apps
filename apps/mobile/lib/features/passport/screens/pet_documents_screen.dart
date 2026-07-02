import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/pet_passport_repository.dart';
import '../domain/pet_passport_models.dart';

class PetDocumentsScreen extends StatefulWidget {
  const PetDocumentsScreen({super.key, this.petId, this.petName});

  final String? petId;
  final String? petName;

  @override
  State<PetDocumentsScreen> createState() => _PetDocumentsScreenState();
}

class _PetDocumentsScreenState extends State<PetDocumentsScreen> {
  final repository = PetPassportRepository();
  late Future<List<PetDocument>> documentsFuture = repository.getDocuments(petId: widget.petId);

  void refresh() {
    setState(() => documentsFuture = repository.getDocuments(petId: widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.petName == null ? 'Документи' : 'Документи ${widget.petName}',
      subtitle: 'Паспорти, довідки, рецепти та аналізи, які власник зберігає для себе.',
      children: [
        FutureBuilder<List<PetDocument>>(
          future: documentsFuture,
          builder: (context, snapshot) {
            final documents = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(message: 'Не вдалося завантажити документи.', onRetry: refresh);
            }
            if (documents.isEmpty) {
              return const EmptyState(
                title: 'Документів поки немає',
                message: 'Додайте скан паспорта, довідку або результат аналізу.',
                icon: Icons.folder_outlined,
              );
            }

            return Column(
              children: documents.map((document) => _DocumentCard(document: document)).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_file),
          label: const Text('Додати документ'),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final PetDocument document;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(document.title),
          subtitle: Text([
            document.fileName ?? 'Файл ще не прикріплено',
            if (document.description != null) document.description!,
          ].join('\n')),
        ),
      ),
    );
  }
}
