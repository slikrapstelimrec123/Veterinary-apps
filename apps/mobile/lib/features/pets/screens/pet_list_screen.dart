import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../data/pet_repository.dart';
import '../domain/pet.dart';
import 'add_pet_screen.dart';
import 'pet_profile_screen.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  final repository = PetRepository();
  late Future<List<Pet>> petsFuture = repository.getPets();

  void refresh() {
    setState(() => petsFuture = repository.getPets());
  }

  Future<void> addPet() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPetScreen()));
    if (result != null) {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Pet>>(
      future: petsFuture,
      builder: (context, snapshot) {
        final pets = snapshot.data ?? [];

        return AppScaffold(
          title: 'Мої тварини',
          subtitle: 'Зберігайте всі медичні картки в одному спокійному місці.',
          children: [
            FilledButton(onPressed: addPet, child: const Text('Додати тварину')),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити тварин.', onRetry: refresh)
            else if (pets.isEmpty)
              EmptyState(
                title: 'Тварин ще немає',
                message: 'Додайте першу тварину, щоб зберігати її медичну історію в одному місці.',
                icon: Icons.pets_outlined,
                action: FilledButton(onPressed: addPet, child: const Text('Додати тварину')),
              )
            else
              ...pets.map((pet) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PetListCard(pet: pet, onChanged: refresh),
                  )),
          ],
        );
      },
    );
  }
}

class _PetListCard extends StatelessWidget {
  const _PetListCard({required this.pet, required this.onChanged});

  final Pet pet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetProfileScreen(petId: pet.id)));
          if (result != null) {
            onChanged();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              PetAvatar(name: pet.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'} · ${pet.ageLabel}'),
                    const SizedBox(height: 4),
                    const Text('Останній візит: поки немає даних', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

