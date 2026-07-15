import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/pets/data/pet_repository.dart';
import '../../../features/pets/domain/pet.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/services/private_pet_storage.dart';

class PetPassportScreen extends StatefulWidget {
  const PetPassportScreen(
      {super.key, required this.petId, required this.petName});

  final String petId;
  final String petName;

  @override
  State<PetPassportScreen> createState() => _PetPassportScreenState();
}

class _PetPassportScreenState extends State<PetPassportScreen> {
  final _repository = PetRepository();
  late Future<Pet?> _petFuture = _repository.getPet(widget.petId);

  void _refresh() =>
      setState(() => _petFuture = _repository.getPet(widget.petId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pet?>(
      future: _petFuture,
      builder: (context, snapshot) {
        final pet = snapshot.data;
        return AppScaffold(
          title: 'Історія лікування',
          subtitle: widget.petName,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити паспорт.', onRetry: _refresh)
            else if (pet == null)
              const EmptyState(
                  title: 'Тварину не знайдено',
                  message: 'Профіль тварини недоступний.',
                  icon: Icons.search_off_outlined)
            else
              _PassportContent(pet: pet, onChanged: _refresh),
          ],
        );
      },
    );
  }
}

class _PassportContent extends StatelessWidget {
  const _PassportContent({required this.pet, required this.onChanged});
  final Pet pet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PassportCard(pet: pet),
        const SizedBox(height: 16),
        _PassportPhotoSection(pet: pet, onChanged: onChanged),
        const SizedBox(height: 16),
        _QrSection(pet: pet),
        const SizedBox(height: 16),
        _InfoSection(pet: pet),
      ],
    );
  }
}

// ─── Passport Photo ───────────────────────────────────────────────────────────

class _PassportPhotoSection extends StatefulWidget {
  const _PassportPhotoSection({required this.pet, required this.onChanged});
  final Pet pet;
  final VoidCallback onChanged;

  @override
  State<_PassportPhotoSection> createState() => _PassportPhotoSectionState();
}

class _PassportPhotoSectionState extends State<_PassportPhotoSection> {
  bool _uploading = false;

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Зробити фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Вибрати з галереї'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      if (!SupabaseConfig.useMockData) {
        final file = File(picked.path);
        final path = await PrivatePetStorage.uploadImage(
          petId: widget.pet.id,
          category: 'passport',
          file: file,
          upsert: true,
        );
        await Supabase.instance.client
            .from('pets')
            .update({'passport_storage_path': path}).eq('id', widget.pet.id);
      }
      if (mounted) {
        widget.onChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото паспорта збережено.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Не вдалося зберегти фото паспорта.'),
              duration: Duration(seconds: 6)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _view() {
    final url = widget.pet.passportPhotoUrl;
    if (url == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PassportPhotoViewer(url: url, petName: widget.pet.name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.pet.passportPhotoUrl != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text('Фото паспорта',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (hasPhoto) ...[
              GestureDetector(
                onTap: _view,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.pet.passportPhotoUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined,
                          color: Colors.grey, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _view,
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: const Text('Переглянути'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploading ? null : _pick,
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_outlined, size: 18),
                      label: const Text('Замінити'),
                    ),
                  ),
                ],
              ),
            ] else
              GestureDetector(
                onTap: _uploading ? null : _pick,
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: _uploading
                      ? const Center(child: CircularProgressIndicator())
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 34, color: AppTheme.textSecondary),
                            SizedBox(height: 6),
                            Text('Завантажити фото паспорта',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PassportPhotoViewer extends StatelessWidget {
  const _PassportPhotoViewer({required this.url, required this.petName});
  final String url;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Паспорт — $petName',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 64),
          ),
        ),
      ),
    );
  }
}

// ─── Passport Card ────────────────────────────────────────────────────────────

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                          '${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}'),
                      Text(pet.ageLabel,
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (pet.microchipNumber != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.memory_outlined,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Мікрочип: ',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  Text(pet.microchipNumber!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── QR ───────────────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  const _QrSection({required this.pet});
  final Pet pet;

  String _buildQrData() {
    final parts = [
      'Lappo — Паспорт тварини',
      'Ім\'я: ${pet.name}',
      'Вид: ${pet.speciesLabel}',
      if (pet.breed != null) 'Порода: ${pet.breed}',
      if (pet.microchipNumber != null) 'Мікрочип: ${pet.microchipNumber}',
      if (pet.weightKg != null) 'Вага: ${pet.weightKg} кг',
      'Для повних даних встановіть Lappo',
    ];
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('QR-код історії лікування',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            QrImageView(
              data: _buildQrData(),
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Відскануйте QR-код для перегляду даних тварини',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info ─────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      _InfoRow('Стать', pet.sexLabel),
      if (pet.isNeutered != null)
        _InfoRow('Стерилізовано', pet.isNeutered! ? 'Так' : 'Ні'),
      if (pet.birthDate != null)
        _InfoRow('Дата народження', _formatDate(pet.birthDate!)),
      if (pet.weightKg != null) _InfoRow('Вага', '${pet.weightKg} кг'),
      if (pet.color != null) _InfoRow('Колір', pet.color!),
      if (pet.notes != null && pet.notes!.isNotEmpty)
        _InfoRow('Нотатки', pet.notes!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Дані тварини',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...rows.map((r) => _InfoTile(label: r.label, value: r.value)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
