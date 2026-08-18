import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../data/visit_record_repository.dart';
import '../domain/visit_record.dart';

class AddVisitRecordScreen extends StatefulWidget {
  const AddVisitRecordScreen(
      {super.key, required this.petId, required this.petName, this.record});

  final String petId;
  final String petName;
  final VisitRecord? record;

  @override
  State<AddVisitRecordScreen> createState() => _AddVisitRecordScreenState();
}

class _AddVisitRecordScreenState extends State<AddVisitRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = VisitRecordRepository();
  final _imagePicker = ImagePicker();

  DateTime _visitDate = DateTime.now();
  final _providerNameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _recommendationsController = TextEditingController();
  bool _nextVisitRecommended = false;
  DateTime? _nextVisitDate;

  bool _saving = false;
  final List<XFile> _attachments = [];

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record == null) return;
    _visitDate = record.visitDate;
    _providerNameController.text = record.providerName ?? '';
    _reasonController.text = record.reason ?? '';
    _symptomsController.text = record.symptoms ?? '';
    _diagnosisController.text = record.diagnosis ?? '';
    _treatmentController.text = record.treatmentNotes ?? '';
    _medicationsController.text = record.prescribedMedications ?? '';
    _recommendationsController.text = record.recommendations ?? '';
    _nextVisitRecommended = record.nextVisitRecommended;
    _nextVisitDate = record.nextVisitDate;
  }

  @override
  void dispose() {
    _providerNameController.dispose();
    _reasonController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _medicationsController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickNextVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _nextVisitDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _nextVisitDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);

    try {
      final VisitRecord? saved;
      if (_isEditing) {
        saved = await _repository.updateSelfReportedVisitRecord(
          id: widget.record!.id,
          petId: widget.petId,
          visitDate: _visitDate,
          reason: _reasonController.text,
          providerName: _providerNameController.text,
          symptoms: _symptomsController.text,
          diagnosis: _diagnosisController.text,
          treatmentNotes: _treatmentController.text,
          prescribedMedications: _medicationsController.text,
          recommendations: _recommendationsController.text,
          nextVisitRecommended: _nextVisitRecommended,
          nextVisitDate: _nextVisitDate,
        );
      } else if (!SupabaseConfig.useMockData) {
        saved = await _repository.createSelfReportedVisitRecord(
          petId: widget.petId,
          visitDate: _visitDate,
          reason: _reasonController.text,
          providerName: _providerNameController.text,
          symptoms: _symptomsController.text,
          diagnosis: _diagnosisController.text,
          treatmentNotes: _treatmentController.text,
          prescribedMedications: _medicationsController.text,
          recommendations: _recommendationsController.text,
          nextVisitRecommended: _nextVisitRecommended,
          nextVisitDate: _nextVisitDate,
        );
      } else {
        saved = null;
      }

      if (saved != null) {
        var failedUploads = 0;
        for (final attachment in _attachments) {
          try {
            await _repository.uploadVisitImage(
              visitRecordId: saved.id,
              petId: widget.petId,
              file: File(attachment.path),
              documentType: 'lab_result',
            );
          } catch (_) {
            failedUploads++;
          }
        }
        if (failedUploads > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Прийом збережено, але не вдалося додати файлів: $failedUploads.',
            ),
          ));
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не вдалося зберегти запис. Спробуйте ще раз.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAttachments() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 88);
    if (images.isEmpty || !mounted) return;
    setState(() {
      for (final image in images) {
        if (_attachments.length >= 10) break;
        if (!_attachments.any((item) => item.path == image.path)) {
          _attachments.add(image);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати прийом' : 'Додати прийом'),
        actions: [
          if (_saving)
            const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _save, child: const Text('Зберегти')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('Загальна інформація'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Дата прийому'),
                      subtitle: Text(_formatDate(_visitDate)),
                      onTap: _pickDate,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _providerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Місце або фахівець (необов\'язково)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Причина та симптоми'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Причина звернення *',
                        border: InputBorder.none,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Вкажіть причину звернення'
                          : null,
                      maxLines: 2,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _symptomsController,
                      decoration: const InputDecoration(
                        labelText: 'Симптоми (необов\'язково)',
                        border: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Результати прийому'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _diagnosisController,
                      decoration: const InputDecoration(
                        labelText: 'Діагноз (необов\'язково)',
                        border: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _treatmentController,
                      decoration: const InputDecoration(
                        labelText: 'Лікування та процедури (необов\'язково)',
                        border: InputBorder.none,
                      ),
                      maxLines: 3,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _medicationsController,
                      decoration: const InputDecoration(
                        labelText: 'Призначені препарати (необов\'язково)',
                        border: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Рекомендації'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _recommendationsController,
                      decoration: const InputDecoration(
                        labelText: 'Рекомендації (необов\'язково)',
                        border: InputBorder.none,
                      ),
                      maxLines: 3,
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Рекомендовано повторний візит'),
                      value: _nextVisitRecommended,
                      onChanged: (v) => setState(() {
                        _nextVisitRecommended = v;
                        if (!v) _nextVisitDate = null;
                      }),
                    ),
                    if (_nextVisitRecommended) ...[
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Дата повторного візиту'),
                        subtitle: Text(_nextVisitDate != null
                            ? _formatDate(_nextVisitDate!)
                            : 'Не вибрано'),
                        onTap: _pickNextVisitDate,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Документи та аналізи'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_attachments.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _attachments.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) => Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_attachments[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: IconButton.filled(
                                visualDensity: VisualDensity.compact,
                                iconSize: 16,
                                onPressed: () => setState(
                                    () => _attachments.removeAt(index)),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_attachments.isNotEmpty) const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed:
                          _attachments.length >= 10 ? null : _pickAttachments,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_attachments.isEmpty
                          ? 'Додати фото документів або аналізів'
                          : 'Додати ще фото'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'До 10 приватних зображень. Вони будуть доступні лише власнику тварини.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (SupabaseConfig.useMockData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Демо-режим: запис не буде збережено в базі даних.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Зберегти запис'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}
