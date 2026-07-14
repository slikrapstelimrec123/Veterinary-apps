import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/achievement_repository.dart';
import '../domain/pet_achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen(
      {super.key, required this.petId, required this.petName});

  final String petId;
  final String petName;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repo = AchievementRepository();
  late Future<List<PetAchievement>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getAchievements(widget.petId);
  }

  void _load() {
    setState(() => _future = _repo.getAchievements(widget.petId));
  }

  Future<void> _delete(PetAchievement a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Видалити подію?'),
        content: Text('«${a.title}» буде видалено назавжди.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Видалити')),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.deleteAchievement(a.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Досягнення',
      subtitle: widget.petName,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddAchievementScreen(petId: widget.petId),
            ));
            if (result == true) _load();
          },
        ),
      ],
      children: [
        FutureBuilder<List<PetAchievement>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(
                  message: 'Не вдалося завантажити досягнення.',
                  onRetry: _load);
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Ще немає подій',
                message:
                    'Додайте змагання, виставки чи інші досягнення вашого улюбленця.',
                action: FilledButton.icon(
                  onPressed: () async {
                    final result =
                        await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddAchievementScreen(petId: widget.petId),
                    ));
                    if (result == true) _load();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Додати подію'),
                ),
              );
            }
            return Column(
              children: items
                  .map((a) => _AchievementCard(
                        achievement: a,
                        onEdit: () async {
                          final result = await Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (_) =>
                                EditAchievementScreen(achievement: a),
                          ));
                          if (result == true) _load();
                        },
                        onDelete: () => _delete(a),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard(
      {required this.achievement,
      required this.onEdit,
      required this.onDelete});

  final PetAchievement achievement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_outlined,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(a.eventTypeLabel,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit),
                  IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppTheme.danger),
                      onPressed: onDelete),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(Icons.calendar_today_outlined, _dateRange(a)),
              if (a.location != null)
                _InfoRow(Icons.location_on_outlined, a.location!),
              if (a.result != null)
                _InfoRow(Icons.leaderboard_outlined, a.result!),
              if (a.awardTitle != null)
                _InfoRow(Icons.military_tech_outlined, a.awardTitle!),
              if (a.notes != null) ...[
                const Divider(height: 16),
                Text(a.notes!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
              if (a.eventPhotoUrl != null || a.awardImageUrl != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (a.eventPhotoUrl != null)
                      Expanded(
                          child: _PhotoThumbnail(
                              url: a.eventPhotoUrl!, label: 'Фото з події')),
                    if (a.eventPhotoUrl != null && a.awardImageUrl != null)
                      const SizedBox(width: 8),
                    if (a.awardImageUrl != null)
                      Expanded(
                          child: _PhotoThumbnail(
                              url: a.awardImageUrl!, label: 'Фото нагороди')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange(PetAchievement a) {
    final start = _fmt(a.eventDate);
    if (a.endDate == null) return start;
    return '$start — ${_fmt(a.endDate!)}';
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.url, required this.label});
  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: Colors.grey.shade200,
              child:
                  const Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ─── Add / Edit ───────────────────────────────────────────────────────────────

class AddAchievementScreen extends StatelessWidget {
  const AddAchievementScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context) {
    return _AchievementForm(
      petId: petId,
      onSave: (a) => AchievementRepository().addAchievement(a),
    );
  }
}

class EditAchievementScreen extends StatelessWidget {
  const EditAchievementScreen({super.key, required this.achievement});
  final PetAchievement achievement;

  @override
  Widget build(BuildContext context) {
    return _AchievementForm(
      petId: achievement.petId,
      initial: achievement,
      onSave: (a) => AchievementRepository().updateAchievement(a),
    );
  }
}

class _AchievementForm extends StatefulWidget {
  const _AchievementForm(
      {required this.petId, required this.onSave, this.initial});

  final String petId;
  final PetAchievement? initial;
  final Future<PetAchievement> Function(PetAchievement) onSave;

  @override
  State<_AchievementForm> createState() => _AchievementFormState();
}

class _AchievementFormState extends State<_AchievementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _resultCtrl = TextEditingController();
  final _awardCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _eventType;
  DateTime _eventDate = DateTime.now();
  DateTime? _endDate;
  bool _saving = false;

  // photos
  File? _eventPhotoFile;
  File? _awardPhotoFile;
  String? _eventPhotoUrl;
  String? _awardPhotoUrl;
  String? _eventPhotoPath;
  String? _awardPhotoPath;

  final _picker = ImagePicker();

  static const _types = [
    ('competition', 'Змагання'),
    ('exhibition', 'Виставка'),
    ('training', 'Тренування'),
    ('certification', 'Сертифікація'),
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    if (a != null) {
      _titleCtrl.text = a.title;
      _locationCtrl.text = a.location ?? '';
      _resultCtrl.text = a.result ?? '';
      _awardCtrl.text = a.awardTitle ?? '';
      _notesCtrl.text = a.notes ?? '';
      _eventType = a.eventType;
      _eventDate = a.eventDate;
      _endDate = a.endDate;
      _eventPhotoUrl = a.eventPhotoUrl;
      _awardPhotoUrl = a.awardImageUrl;
      _eventPhotoPath = a.eventPhotoPath;
      _awardPhotoPath = a.awardImagePath;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _resultCtrl.dispose();
    _awardCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(bool isEvent) async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      if (isEvent) {
        _eventPhotoFile = File(picked.path);
      } else {
        _awardPhotoFile = File(picked.path);
      }
    });
  }

  Future<String?> _uploadPhoto(File file, String folder) async {
    if (SupabaseConfig.useMockData) return null;
    return PrivatePetStorage.uploadImage(
      petId: widget.petId,
      category: 'achievements/$folder',
      file: file,
    );
  }

  Future<void> _pickDate(bool isEnd) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isEnd ? (_endDate ?? _eventDate) : _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _endDate = picked;
        } else {
          _eventDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? eventUrl = _eventPhotoUrl;
      String? awardUrl = _awardPhotoUrl;
      String? eventPath = _eventPhotoPath;
      String? awardPath = _awardPhotoPath;

      if (_eventPhotoFile != null) {
        eventPath = await _uploadPhoto(_eventPhotoFile!, 'events');
      }
      if (_awardPhotoFile != null) {
        awardPath = await _uploadPhoto(_awardPhotoFile!, 'awards');
      }

      final a = PetAchievement(
        id: widget.initial?.id ?? '',
        petId: widget.petId,
        title: _titleCtrl.text.trim(),
        eventDate: _eventDate,
        endDate: _endDate,
        eventType: _eventType,
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        result:
            _resultCtrl.text.trim().isEmpty ? null : _resultCtrl.text.trim(),
        awardTitle:
            _awardCtrl.text.trim().isEmpty ? null : _awardCtrl.text.trim(),
        awardImageUrl: awardUrl,
        eventPhotoUrl: eventUrl,
        awardImagePath: awardPath,
        eventPhotoPath: eventPath,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await widget.onSave(a);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'),
              duration: const Duration(seconds: 10)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редагувати подію' : 'Нова подія'),
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
            const _Label('Основне'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Назва події *',
                        border: InputBorder.none,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Вкажіть назву'
                          : null,
                    ),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      initialValue: _eventType,
                      decoration: const InputDecoration(
                          labelText: 'Тип події', border: InputBorder.none),
                      items: _types
                          .map((t) =>
                              DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                          .toList(),
                      onChanged: (v) => setState(() => _eventType = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Дати'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Дата початку'),
                      subtitle: Text(_fmt(_eventDate)),
                      onTap: () => _pickDate(false),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Дата кінця (необов\'язково)'),
                      subtitle: Text(
                          _endDate != null ? _fmt(_endDate!) : 'Не вказано'),
                      onTap: () => _pickDate(true),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _endDate = null),
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Деталі'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Місце проведення (необов\'язково)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _resultCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Результат / місце (необов\'язково)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.leaderboard_outlined),
                      ),
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _awardCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Нагорода / титул (необов\'язково)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.military_tech_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Фото'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _PhotoPicker(
                  label: 'Фото з події',
                  icon: Icons.photo_camera_outlined,
                  file: _eventPhotoFile,
                  existingUrl: _eventPhotoUrl,
                  onPick: () => _pickPhoto(true),
                  onRemove: () => setState(() {
                    _eventPhotoFile = null;
                    _eventPhotoUrl = null;
                  }),
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _PhotoPicker(
                  label: 'Фото нагороди',
                  icon: Icons.military_tech_outlined,
                  file: _awardPhotoFile,
                  existingUrl: _awardPhotoUrl,
                  onPick: () => _pickPhoto(false),
                  onRemove: () => setState(() {
                    _awardPhotoFile = null;
                    _awardPhotoUrl = null;
                  }),
                )),
              ],
            ),
            const SizedBox(height: 16),
            const _Label('Нотатки'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Нотатки (необов\'язково)',
                    border: InputBorder.none,
                  ),
                  maxLines: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(isEdit ? 'Зберегти зміни' : 'Додати подію'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.label,
    required this.icon,
    required this.onPick,
    required this.onRemove,
    this.file,
    this.existingUrl,
  });

  final String label;
  final IconData icon;
  final File? file;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = file != null || existingUrl != null;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: file != null
                        ? Image.file(file!, fit: BoxFit.cover)
                        : Image.network(existingUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined)),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: AppTheme.textSecondary),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}
