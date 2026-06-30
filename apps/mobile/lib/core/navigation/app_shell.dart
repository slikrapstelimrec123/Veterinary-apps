import 'package:flutter/material.dart';

import '../../features/appointments/screens/my_appointments_screen.dart';
import '../../features/clinics/screens/clinic_list_screen.dart';
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
      const ClinicListScreen(),
      const MyAppointmentsScreen(),
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
            onDestinationSelected: (value) {
              setState(() => _index = value);
              if (value == 4) {
                refreshUnreadCount();
              }
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
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClinicListScreen())),
                child: const Text('Знайти клініку'),
              ),
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
            Text('Beta-тестування VetCare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Зберігайте медичну історію тварини в одному місці, знаходьте клініку та бронюйте прийом.'),
            SizedBox(height: 10),
            Text('Кроки: додайте тварину → знайдіть клініку → створіть запис.'),
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
            const Text('Найближчий запис: у розділі записів'),
            const SizedBox(height: 6),
            const Text('Останній візит: поки немає даних'),
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
