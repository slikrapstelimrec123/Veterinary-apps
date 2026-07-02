import 'package:flutter/material.dart';

import '../../features/appointments/screens/appointments_coming_soon_screen.dart';
import '../../features/clinics/screens/clinic_coming_soon_screen.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/screens/notifications_screen.dart';
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
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final notificationRepository = NotificationRepository();
  late Future<int> unreadFuture = notificationRepository.getUnreadCount();

  void refreshUnreadCount() {
    setState(() => unreadFuture = notificationRepository.getUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onOpenPets: () => setState(() => _index = 1)),
      const PetListScreen(),
      const ClinicComingSoonScreen(),
      const AppointmentsComingSoonScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: FutureBuilder<int>(
        future: unreadFuture,
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return NavigationBar(
            selectedIndex: _index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (value) {
              setState(() => _index = value);
              if (value == 4) refreshUnreadCount();
            },
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Головна'),
              const NavigationDestination(icon: Icon(Icons.pets_outlined), label: 'Тварини'),
              const NavigationDestination(icon: Icon(Icons.local_hospital_outlined), label: 'Клініки'),
              const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Записи'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: const Icon(Icons.notifications_none_outlined),
                ),
                label: 'Сповіщення',
              ),
              const NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Налаштування'),
            ],
          );
        },
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
    if (result != null) refresh();
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
          subtitle: 'Медична картка ваших тварин завжди під рукою.',
          showLogo: true,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити головну сторінку.', onRetry: refresh)
            else ...[
              _SummaryCard(petCount: pets.length),
              const SizedBox(height: 12),
              if (pets.isEmpty)
                EmptyState(
                  title: 'Додайте першу тварину',
                  message: 'Створіть медичну картку, щоб зберігати всю інформацію про здоров\'я вашого улюбленця.',
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
                const SizedBox(height: 4),
                ...pets.take(3).map((pet) => _HomePetPreview(pet: pet, onChanged: refresh)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: addPet,
                  icon: const Icon(Icons.add),
                  label: const Text('Додати тварину'),
                ),
              ],
              const SizedBox(height: 12),
              const _ClinicComingSoonCard(),
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
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.pets_outlined,
                value: '$petCount',
                label: petCount == 1 ? 'тварина' : petCount < 5 ? 'тварини' : 'тварин',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _StatTile(
                icon: Icons.history_outlined,
                value: '0',
                label: 'прийомів',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _StatTile(
                icon: Icons.folder_outlined,
                value: '0',
                label: 'документів',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

class _ClinicComingSoonCard extends StatelessWidget {
  const _ClinicComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text('Клініки — незабаром', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Незабаром ви зможете знаходити клініки та записуватися на прийом прямо в застосунку.',
              style: TextStyle(color: AppTheme.textSecondary),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: PetAvatar(name: pet.name),
          title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final result = await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PetProfileScreen(petId: pet.id),
            ));
            if (result != null) onChanged();
          },
        ),
      ),
    );
  }
}
