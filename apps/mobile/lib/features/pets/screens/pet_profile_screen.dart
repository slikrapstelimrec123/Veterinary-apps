import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../../achievements/screens/achievements_screen.dart';
import '../../feeding/screens/feeding_screen.dart';
import '../../medications/screens/medications_screen.dart';
import '../../passport/screens/pet_passport_screen.dart';
import '../../visit_records/screens/documents_screen.dart';
import '../../visit_records/screens/visit_history_screen.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';
import 'edit_pet_screen.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key, required this.petId});

  final String petId;

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final repository = PetRepository();
  late Future<Pet?> petFuture = repository.getPet(widget.petId);

  void refresh() {
    setState(() => petFuture = repository.getPet(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pet?>(
      future: petFuture,
      builder: (context, snapshot) {
        final pet = snapshot.data;

        return AppScaffold(
          title: pet?.name ?? 'Профіль тварини',
          subtitle: pet == null ? null : '${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити профіль тварини.', onRetry: refresh)
            else if (pet == null)
              const EmptyState(title: 'Тварину не знайдено', message: 'Цей профіль тварини недоступний.', icon: Icons.search_off_outlined)
            else
              _PetProfileContent(pet: pet, onChanged: refresh),
          ],
        );
      },
    );
  }
}

class _PetProfileContent extends StatelessWidget {
  const _PetProfileContent({required this.pet, required this.onChanged});

  final Pet pet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PetCard(pet: pet),
        const SizedBox(height: 12),
        _ActionGrid(pet: pet, onChanged: onChanged),
        const SizedBox(height: 12),
        _DetailSection(pet: pet, onChanged: onChanged),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditPetScreen(pet: pet)));
            if (result != null) {
              onChanged();
              if (context.mounted) Navigator.of(context).pop(result);
            }
          },
          child: const Text('Редагувати дані тварини'),
        ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PetAvatar(name: pet.name, size: 82),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('${pet.speciesLabel} · ${pet.ageLabel}', style: const TextStyle(color: AppTheme.textSecondary)),
                  if (pet.breed != null) ...[
                    const SizedBox(height: 2),
                    Text(pet.breed!, style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.pet, required this.onChanged});
  final Pet pet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.history_outlined,
                title: 'Прийоми',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => VisitHistoryScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.folder_outlined,
                title: 'Документи',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DocumentsScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.medication_outlined,
                title: 'Препарати',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MedicationsScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.qr_code_outlined,
                title: 'Паспорт / QR',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PetPassportScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.restaurant_outlined,
                title: 'Харчування',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FeedingScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.emoji_events_outlined,
                title: 'Досягнення',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AchievementsScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.onTap, this.badge});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Text(badge!, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatefulWidget {
  const _DetailSection({required this.pet, required this.onChanged});
  final Pet pet;
  final VoidCallback onChanged;

  @override
  State<_DetailSection> createState() => _DetailSectionState();
}

class _DetailSectionState extends State<_DetailSection> {
  bool _uploadingPassport = false;

  Future<void> _uploadPassportPhoto() async {
    final picker = ImagePicker();
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

    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _uploadingPassport = true);
    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      final path = 'passports/${widget.pet.id}.$ext';
      final client = Supabase.instance.client;
      await client.storage.from('pet-documents').upload(path, file,
          fileOptions: const FileOptions(upsert: true));
      final url = client.storage.from('pet-documents').getPublicUrl(path);
      await client.from('pets').update({'passport_photo_url': url}).eq('id', widget.pet.id);
      if (mounted) {
        widget.onChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото паспорта збережено.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), duration: const Duration(seconds: 8)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPassport = false);
    }
  }

  void _viewPassport() {
    final url = widget.pet.passportPhotoUrl;
    if (url == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PassportPhotoViewer(url: url, petName: widget.pet.name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final neuteredLabel = pet.isNeutered == null
        ? 'Не вказано'
        : pet.isNeutered! ? 'Так' : 'Ні';
    final details = <(String, String)>[
      ('Стать', pet.sexLabel),
      ('Кастровано', neuteredLabel),
      ('Вага', pet.weightKg == null ? 'Не вказано' : '${pet.weightKg} кг'),
      ('Колір', pet.color ?? 'Не вказано'),
      ('Мікрочип', pet.microchipNumber ?? 'Не вказано'),
      if (pet.notes != null && pet.notes!.isNotEmpty) ('Нотатки', pet.notes!),
    ];

    final hasPassport = pet.passportPhotoUrl != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Основна інформація', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...details.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(item.$1, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                    Expanded(child: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text('Фото паспорта', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            if (hasPassport) ...[
              GestureDetector(
                onTap: _viewPassport,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    pet.passportPhotoUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _viewPassport,
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: const Text('Переглянути'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingPassport ? null : _uploadPassportPhoto,
                      icon: _uploadingPassport
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_outlined, size: 18),
                      label: const Text('Замінити'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              GestureDetector(
                onTap: _uploadingPassport ? null : _uploadPassportPhoto,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: _uploadingPassport
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppTheme.textSecondary),
                            const SizedBox(height: 6),
                            const Text('Завантажити фото паспорта',
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                ),
              ),
            ],
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
        title: Text('Паспорт — $petName', style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}
