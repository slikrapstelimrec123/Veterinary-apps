import 'dart:io';

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
          const SnackBar(content: Text('Не вдалося відкрити документ.')),
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
          const SnackBar(content: Text('Не вдалося завантажити документ.')),
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
                  '${widget.document.type} - ${widget.document.fileSizeLabel} - ${widget.document.createdAt.toIso8601String().split('T').first}'),
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

class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  final String title;
  final String fileName;
  final Uint8List bytes;

  bool get _isPdf => fileName.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Colors.black,
      body: _isPdf
          ? PdfViewer.data(bytes)
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
    );
  }
}
