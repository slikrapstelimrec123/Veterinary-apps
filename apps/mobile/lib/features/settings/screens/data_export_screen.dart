import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../services/data_export_service.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final _service = DataExportService();
  bool _isExporting = false;

  Future<void> _export() async {
    setState(() => _isExporting = true);
    DataExportResult? result;
    try {
      result = await _service.createExport();
      if (!mounted) return;
      await Share.shareXFiles(
          [XFile(result.file.path, mimeType: 'application/zip')],
          subject: 'Експорт даних Lappo');
      if (!mounted) return;
      final details = result.warnings.isEmpty
          ? 'Архів створено. Додано файлів: ${result.exportedFileCount}.'
          : 'Архів створено, але деякі дані недоступні. Додано файлів: ${result.exportedFileCount}.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(details), duration: const Duration(seconds: 6)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не вдалося створити експорт. Спробуйте ще раз.')));
    } finally {
      final temporaryFile = result?.file;
      if (temporaryFile != null) {
        try {
          if (await temporaryFile.exists()) await temporaryFile.delete();
        } catch (_) {
          // The OS may still hold the shared file briefly; the temporary
          // directory remains isolated and will be cleaned by the platform.
        }
      }
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Експорт даних',
      subtitle: 'Завантажте копію інформації та доступних медичних файлів.',
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.folder_zip_outlined),
                SizedBox(width: 12),
                Expanded(
                    child: Text('Що буде в архіві',
                        style: TextStyle(fontWeight: FontWeight.w700)))
              ]),
              SizedBox(height: 14),
              Text('• профіль і налаштування сповіщень'),
              Text('• інформація про ваших тварин'),
              Text('• записи на прийом і медична історія'),
              Text('• доступні вам документи та фото'),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
            child: ListTile(
          leading: Icon(Icons.shield_outlined),
          title: Text('Приватні медичні дані'),
          subtitle: Text(
              'Архів створюється лише з даних, доступних вашому акаунту. Зберігайте його у безпечному місці.'),
        )),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isExporting ? null : _export,
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_outlined),
          label: Text(_isExporting
              ? 'Створення архіву...'
              : 'Створити та зберегти ZIP'),
        ),
      ],
    );
  }
}
