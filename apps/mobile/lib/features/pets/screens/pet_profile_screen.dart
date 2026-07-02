import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../passport/screens/passport_tools_screen.dart';
import '../../passport/screens/pet_documents_screen.dart';
import '../../passport/screens/preventive_care_screen.dart';
import '../../passport/screens/reminders_screen.dart';
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
          subtitle: pet == null ? 'Завантаження медичної картки.' : '${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}',
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                PetAvatar(name: pet.name, size: 82),
                const SizedBox(height: 12),
                Text(pet.name, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('${pet.speciesLabel} · ${pet.ageLabel}', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _DetailGrid(pet: pet),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PreventiveCareScreen(petId: pet.id, petName: pet.name))),
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Профілактика і вакцинації'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditPetScreen(pet: pet)));
            if (result != null) {
              onChanged();
              if (context.mounted) {
                Navigator.of(context).pop(result);
              }
            }
          },
          child: const Text('Редагувати тварину'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetRemindersScreen(petId: pet.id, petName: pet.name))),
          child: const Text('Нагадування'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetDocumentsScreen(petId: pet.id, petName: pet.name))),
          child: const Text('Документи'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PassportToolsScreen(petId: pet.id, petName: pet.name))),
          child: const Text('QR / PDF картка'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VisitHistoryScreen(petId: pet.id, petName: pet.name))),
          child: const Text('Історія лікування від клінік'),
        ),
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final details = [
      ('Стать', pet.sexLabel),
      ('Дата народження', pet.birthDate?.toIso8601String().split('T').first ?? 'Не вказано'),
      ('Вага', pet.weightKg == null ? 'Не вказано' : '${pet.weightKg} кг'),
      ('Колір', pet.color ?? 'Не вказано'),
      ('Мікрочип', pet.microchipNumber ?? 'Не вказано'),
      ('Стерилізація', pet.sterilized == true ? 'Так' : 'Не вказано'),
      ('Алергії', pet.allergies ?? 'Не вказано'),
      ('Хронічні стани', pet.chronicConditions ?? 'Не вказано'),
      ('Контакт власника', pet.ownerContactPhone ?? pet.ownerContactEmail ?? 'Не вказано'),
      ('Екстрений контакт', pet.emergencyContact ?? 'Не вказано'),
      ('Нотатки', pet.notes ?? 'Нотаток поки немає'),
    ];

    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: _QuickCard(title: 'Останній візит', value: 'Поки немає даних')),
            SizedBox(width: 10),
            Expanded(child: _QuickCard(title: 'QR / PDF', value: 'Готово до налаштування')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(child: _QuickCard(title: 'Найближче', value: 'Нагадування')),
          ],
        ),
        const SizedBox(height: 12),
        ...details.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 96, child: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800))),
                      Expanded(child: Text(item.$2)),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}
