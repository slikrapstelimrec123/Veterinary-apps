import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../../shared/navigation/instant_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../achievements/screens/achievements_screen.dart';
import '../../feeding/screens/feeding_screen.dart';
import '../../medications/screens/medications_screen.dart';
import '../../passport/screens/pet_passport_screen.dart';
import '../../visit_records/screens/documents_screen.dart';
import '../../visit_records/screens/visit_history_screen.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';
import '../../announcements/screens/add_sale_announcement_screen.dart';
import '../../announcements/screens/add_breeding_announcement_screen.dart';
import 'edit_pet_screen.dart';
import 'transfer_pet_screen.dart';

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
    setState(() {
      petFuture = repository.getPet(widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Pet?>(
      future: petFuture,
      builder: (context, snapshot) {
        final pet = snapshot.data;

        return AppScaffold(
          title: pet?.name ?? 'Профіль тварини',
          subtitle: pet == null
              ? null
              : '${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                  message: 'Не вдалося завантажити профіль тварини.',
                  onRetry: refresh)
            else if (pet == null)
              const EmptyState(
                  title: 'Тварину не знайдено',
                  message: 'Цей профіль тварини недоступний.',
                  icon: Icons.search_off_outlined)
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
            final result = await Navigator.of(context).push(
                InstantPageRoute(builder: (_) => EditPetScreen(pet: pet)));
            if (result == 'deleted') {
              if (context.mounted) Navigator.of(context).pop('deleted');
            } else if (result != null) {
              onChanged();
              if (context.mounted) Navigator.of(context).pop(result);
            }
          },
          child: const Text('Редагувати дані тварини'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(InstantPageRoute(
            builder: (_) => AddSaleAnnouncementScreen(pet: pet),
          )),
          icon: const Icon(Icons.favorite_border),
          label: const Text('Додати оголошення про цуценят'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(InstantPageRoute(
            builder: (_) => AddBreedingAnnouncementScreen(pet: pet),
          )),
          icon: const Icon(Icons.diversity_1_outlined),
          label: const Text('Пошук партнера'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(InstantPageRoute(
            builder: (_) => TransferPetScreen(pet: pet),
          )),
          icon: const Icon(Icons.qr_code),
          label: const Text('Передати картку тварини'),
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
            PetAvatar(name: pet.name, avatarUrl: pet.avatarUrl, size: 82),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('${pet.speciesLabel} · ${pet.ageLabel}',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  if (pet.breed != null) ...[
                    const SizedBox(height: 2),
                    Text(pet.breed!,
                        style: const TextStyle(color: AppTheme.textSecondary)),
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
                onTap: () => Navigator.of(context).push(InstantPageRoute(
                  builder: (_) =>
                      VisitHistoryScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.folder_outlined,
                title: 'Документи',
                onTap: () => Navigator.of(context).push(InstantPageRoute(
                  builder: (_) =>
                      DocumentsScreen(petId: pet.id, petName: pet.name),
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
                onTap: () => Navigator.of(context).push(InstantPageRoute(
                  builder: (_) =>
                      MedicationsScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.qr_code_outlined,
                title: 'Паспорт',
                onTap: () => Navigator.of(context).push(InstantPageRoute(
                  builder: (_) =>
                      PetPassportScreen(petId: pet.id, petName: pet.name),
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
                onTap: () => Navigator.of(context).push(InstantPageRoute(
                  builder: (_) =>
                      FeedingScreen(petId: pet.id, petName: pet.name),
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.emoji_events_outlined,
                title: 'Досягнення',
                onTap: () => Navigator.of(context).push(InstantPageRoute(
                  builder: (_) =>
                      AchievementsScreen(petId: pet.id, petName: pet.name),
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
  const _ActionCard(
      {required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

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
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
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
  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final neuteredLabel = pet.isNeutered == null
        ? 'Не вказано'
        : pet.isNeutered!
            ? 'Так'
            : 'Ні';
    final details = <(String, String)>[
      ('Стать', pet.sexLabel),
      ('Стерилізовано', neuteredLabel),
      ('Вага', pet.weightKg == null ? 'Не вказано' : '${pet.weightKg} кг'),
      ('Колір', pet.color ?? 'Не вказано'),
      ('Мікрочип', pet.microchipNumber ?? 'Не вказано'),
      if (pet.notes != null && pet.notes!.isNotEmpty) ('Нотатки', pet.notes!),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Основна інформація',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...details.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(item.$1,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: Text(item.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
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
