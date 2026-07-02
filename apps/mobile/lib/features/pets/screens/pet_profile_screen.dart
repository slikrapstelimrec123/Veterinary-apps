import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../../core/theme/app_theme.dart';
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
        _DetailSection(pet: pet),
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
        child: Column(
          children: [
            PetAvatar(name: pet.name, size: 82),
            const SizedBox(height: 12),
            Text(pet.name, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('${pet.speciesLabel} · ${pet.ageLabel}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            if (pet.breed != null) ...[
              const SizedBox(height: 2),
              Text(pet.breed!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            ],
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
        SizedBox(
          width: double.infinity,
          child: _ActionCard(
            icon: Icons.calendar_month_outlined,
            title: 'Записатись до ветеринара',
            badge: 'Незабаром',
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Незабаром'),
                content: const Text(
                  'Онлайн-запис до ветеринара буде доступний після підключення клінік до платформи.\n\nТим часом ви можете самостійно додати запис про прийом у розділі "Прийоми".',
                ),
                actions: [
                  FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Зрозуміло')),
                ],
              ),
            ),
          ),
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final details = <(String, String)>[
      ('Стать', pet.sexLabel),
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
          ],
        ),
      ),
    );
  }
}
