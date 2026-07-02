import 'package:flutter/material.dart';

import '../../features/clinics/screens/clinic_list_screen.dart';
import '../../features/passport/screens/passport_tools_screen.dart';
import '../../features/passport/screens/pet_documents_screen.dart';
import '../../features/passport/screens/reminders_screen.dart';
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
      HomeScreen(
        onOpenPets: () => setState(() => _index = 1),
        onOpenReminders: () => setState(() => _index = 2),
        onOpenDocuments: () => setState(() => _index = 3),
        onOpenPassportTools: () => setState(() => _index = 4),
      ),
      const PetListScreen(),
      const PetRemindersScreen(),
      const PetDocumentsScreen(),
      const PassportToolsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Головна'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), label: 'Тварини'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Нагадування'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Документи'),
          NavigationDestination(icon: Icon(Icons.qr_code_2_outlined), label: 'QR/PDF'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Налаштування'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenPets,
    required this.onOpenReminders,
    required this.onOpenDocuments,
    required this.onOpenPassportTools,
  });

  final VoidCallback onOpenPets;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenPassportTools;

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
          title: 'Вітаємо, ${user?.fullName.split(' ').first ?? 'друже'}',
          subtitle: 'Історія здоров’я ваших тварин в одному спокійному місці.',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити головну сторінку.', onRetry: refresh)
            else ...[
              const _BetaWelcomeCard(),
              const SizedBox(height: 12),
              _SummaryCard(petCount: pets.length),
              const SizedBox(height: 12),
              _PassportActions(
                onOpenPets: widget.onOpenPets,
                onOpenReminders: widget.onOpenReminders,
                onOpenDocuments: widget.onOpenDocuments,
                onOpenPassportTools: widget.onOpenPassportTools,
              ),
              const SizedBox(height: 12),
              if (pets.isEmpty)
                EmptyState(
                  title: 'Створіть медичну картку',
                  message: 'Додайте тварину, щоб почати вести її медичну історію.',
                  icon: Icons.pets_outlined,
                  action: FilledButton(onPressed: addPet, child: const Text('Додати тварину')),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ваші тварини', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(onPressed: widget.onOpenPets, child: const Text('Переглянути всі')),
                  ],
                ),
                ...pets.take(2).map((pet) => _HomePetPreview(pet: pet, onChanged: refresh)),
                const SizedBox(height: 12),
                FilledButton(onPressed: addPet, child: const Text('Додати тварину')),
              ],
              const SizedBox(height: 8),
              const _ClinicPilotCard(),
            ],
          ],
        );
      },
    );
  }
}

class _BetaWelcomeCard extends StatelessWidget {
  const _BetaWelcomeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Цифровий паспорт тварини', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Зберігайте паспорт, медичні події, документи та нагадування в одному місці.'),
            SizedBox(height: 10),
            Text('Кроки: додайте тварину → внесіть вакцинації → увімкніть QR або підготуйте PDF.'),
          ],
        ),
      ),
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
            Text('Підсумок здоров’я', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Тварин: $petCount'),
            const SizedBox(height: 6),
            const Text('Найближче нагадування: у розділі нагадувань'),
            const SizedBox(height: 6),
            const Text('PDF/QR: доступно після створення паспорта'),
          ],
        ),
      ),
    );
  }
}

class _PassportActions extends StatelessWidget {
  const _PassportActions({
    required this.onOpenPets,
    required this.onOpenReminders,
    required this.onOpenDocuments,
    required this.onOpenPassportTools,
  });

  final VoidCallback onOpenPets;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenPassportTools;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ActionCard(icon: Icons.pets_outlined, title: 'Паспорти', onTap: onOpenPets)),
            const SizedBox(width: 10),
            Expanded(child: _ActionCard(icon: Icons.event_note_outlined, title: 'Нагадування', onTap: onOpenReminders)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _ActionCard(icon: Icons.folder_outlined, title: 'Документи', onTap: onOpenDocuments)),
            const SizedBox(width: 10),
            Expanded(child: _ActionCard(icon: Icons.qr_code_2_outlined, title: 'QR / PDF', onTap: onOpenPassportTools)),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.onTap});

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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicPilotCard extends StatelessWidget {
  const _ClinicPilotCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Клініки — пілотний режим', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Пошук клінік і запис на прийом залишаються в коді, але не є головним сценарієм цього MVP.'),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClinicListScreen())),
              child: const Text('Переглянути пілот клінік'),
            ),
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
          subtitle: Text('${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}'),
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
