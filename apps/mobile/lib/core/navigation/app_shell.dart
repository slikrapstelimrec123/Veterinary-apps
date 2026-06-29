import 'package:flutter/material.dart';

import '../../features/clinics/screens/clinic_placeholder_screen.dart';
import '../../features/pets/data/pet_repository.dart';
import '../../features/pets/domain/pet.dart';
import '../../features/pets/screens/add_pet_screen.dart';
import '../../features/pets/screens/pet_list_screen.dart';
import '../../features/pets/screens/pet_profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/pet_avatar.dart';
import '../auth/auth_state.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onOpenPets: () => setState(() => _index = 1)),
      const PetListScreen(),
      const ClinicPlaceholderScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), label: 'Pets'),
          NavigationDestination(icon: Icon(Icons.local_hospital_outlined), label: 'Clinics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenPets});

  final VoidCallback onOpenPets;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final user = AuthScope.of(context).currentUser;

    return FutureBuilder<List<Pet>>(
      future: petsFuture,
      builder: (context, snapshot) {
        final pets = snapshot.data ?? [];

        return AppScaffold(
          title: 'Hello, ${user?.fullName.split(' ').first ?? 'there'}',
          subtitle: 'Your pet health history in one calm place.',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Unable to load home data.', onRetry: refresh)
            else ...[
              _SummaryCard(petCount: pets.length),
              const SizedBox(height: 12),
              if (pets.isEmpty)
                EmptyState(
                  title: 'Start a medical card',
                  message: 'Add your pet to start building their medical history.',
                  icon: Icons.pets_outlined,
                  action: FilledButton(onPressed: addPet, child: const Text('Add pet')),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your pets', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(onPressed: widget.onOpenPets, child: const Text('View all')),
                  ],
                ),
                ...pets.take(2).map((pet) => _HomePetPreview(pet: pet, onChanged: refresh)),
                const SizedBox(height: 12),
                FilledButton(onPressed: addPet, child: const Text('Add pet')),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClinicPlaceholderScreen())),
                child: const Text('Find a clinic'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.petCount});

  final int petCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Pets: $petCount'),
            const SizedBox(height: 6),
            const Text('Upcoming appointment: next stage'),
            const SizedBox(height: 6),
            const Text('Last visit: placeholder'),
          ],
        ),
      ),
    );
  }
}

class _HomePetPreview extends StatelessWidget {
  const _HomePetPreview({required this.pet, required this.onChanged});

  final Pet pet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: PetAvatar(name: pet.name),
          title: Text(pet.name),
          subtitle: Text('${pet.speciesLabel} · ${pet.breed ?? 'Breed not set'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetProfileScreen(petId: pet.id)));
            if (result != null) {
              onChanged();
            }
          },
        ),
      ),
    );
  }
}

