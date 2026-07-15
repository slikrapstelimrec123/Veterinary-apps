import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/announcements/screens/announcements_screen.dart';
import '../../features/medications/data/medication_repository.dart';
import '../../features/medications/screens/medications_screen.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/pets/data/pet_repository.dart';
import '../../features/pets/domain/pet.dart';
import '../../features/pets/screens/add_pet_screen.dart';
import '../../features/pets/screens/pet_list_screen.dart';
import '../../features/pets/screens/pet_profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/visit_records/data/visit_record_repository.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/pet_avatar.dart';
import '../auth/auth_state.dart';
import '../config/supabase_config.dart';
import '../notifications/local_notification_service.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  final _tabVersions = List<int>.filled(5, 0);
  RealtimeChannel? _notificationChannel;
  final notificationRepository = NotificationRepository();
  late Future<int> unreadFuture = notificationRepository.getUnreadCount();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureSystemNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() {
      for (var index = 0; index < _tabVersions.length; index++) {
        _tabVersions[index]++;
      }
      unreadFuture = notificationRepository.getUnreadCount();
    });
  }

  Future<void> _configureSystemNotifications() async {
    if (SupabaseConfig.useMockData) return;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    await LocalNotificationService.instance.initialize();
    await LocalNotificationService.instance.requestPermission();

    _notificationChannel = client
        .channel('mobile-notifications-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_user_id',
            value: user.id,
          ),
          callback: (payload) {
            final notification = AppNotification.fromJson(payload.newRecord);
            LocalNotificationService.instance.show(notification);
            if (mounted) {
              _tabVersions[3]++;
              refreshUnreadCount();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final channel = _notificationChannel;
    if (channel != null && SupabaseConfig.isConfigured) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  void refreshUnreadCount() {
    setState(() {
      unreadFuture = notificationRepository.getUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
          key: ValueKey('home-${_tabVersions[0]}'),
          onOpenPets: () => setState(() {
                _index = 1;
                _tabVersions[1]++;
              })),
      PetListScreen(key: ValueKey('pets-${_tabVersions[1]}')),
      AnnouncementsScreen(key: ValueKey('announcements-${_tabVersions[2]}')),
      NotificationsScreen(key: ValueKey('notifications-${_tabVersions[3]}')),
      SettingsScreen(key: ValueKey('settings-${_tabVersions[4]}')),
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
              setState(() {
                _index = value;
                _tabVersions[value]++;
              });
              if (value == 3) refreshUnreadCount();
            },
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.home_outlined), label: 'Home'),
              const NavigationDestination(
                  icon: Icon(Icons.pets_outlined), label: 'Pets'),
              const NavigationDestination(
                  icon: Icon(Icons.campaign_outlined), label: 'Announcements'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 9 ? '9+' : '$unread'),
                  child: const Icon(Icons.notifications_none_outlined),
                ),
                label: 'Notifications',
              ),
              const NavigationDestination(
                  icon: Icon(Icons.settings_outlined), label: 'Settings'),
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
  final visitRepository = VisitRecordRepository();
  late Future<List<Pet>> petsFuture = repository.getPets();
  int _visitCount = 0;
  int _documentCount = 0;

  void refresh() {
    setState(() => petsFuture = repository.getPets());
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final pets = await repository.getPets();
    int visits = 0;
    int docs = 0;
    for (final pet in pets) {
      final records = await visitRepository.getVisitRecordsForPet(pet.id);
      visits += records.length;
      final documents = await visitRepository.getDocumentsForPet(pet.id);
      docs += documents.length;
    }
    if (mounted) {
      setState(() {
        _visitCount = visits;
        _documentCount = docs;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> addPet() async {
    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddPetScreen()));
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
              ErrorState(
                  message: 'Не вдалося завантажити головну сторінку.',
                  onRetry: refresh)
            else ...[
              _SummaryCard(
                  petCount: pets.length,
                  visitCount: _visitCount,
                  documentCount: _documentCount),
              const SizedBox(height: 12),
              if (pets.isEmpty)
                EmptyState(
                  title: 'Додайте першу тварину',
                  message:
                      'Створіть медичну картку, щоб зберігати всю інформацію про здоров\'я вашого улюбленця.',
                  icon: Icons.pets_outlined,
                  action: FilledButton(
                      onPressed: addPet, child: const Text('Додати тварину')),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                        child: Text('Ваші тварини',
                            style: Theme.of(context).textTheme.titleLarge)),
                    TextButton(
                        onPressed: widget.onOpenPets,
                        child: const Text('Переглянути всі')),
                  ],
                ),
                const SizedBox(height: 4),
                ...pets.take(3).map(
                    (pet) => _HomePetPreview(pet: pet, onChanged: refresh)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: addPet,
                  icon: const Icon(Icons.add),
                  label: const Text('Додати тварину'),
                ),
              ],
              const SizedBox(height: 12),
              const _ClinicComingSoonCard(),
              const SizedBox(height: 12),
              _UpcomingEventsCard(pets: pets),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.petCount,
      required this.visitCount,
      required this.documentCount});

  final int petCount;
  final int visitCount;
  final int documentCount;

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
                label: petCount == 1
                    ? 'тварина'
                    : petCount < 5
                        ? 'тварини'
                        : 'тварин',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                icon: Icons.history_outlined,
                value: '$visitCount',
                label: visitCount == 1
                    ? 'прийом'
                    : visitCount < 5
                        ? 'прийоми'
                        : 'прийомів',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                icon: Icons.folder_outlined,
                value: '$documentCount',
                label: documentCount == 1
                    ? 'документ'
                    : documentCount < 5
                        ? 'документи'
                        : 'документів',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
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
                const Icon(Icons.campaign_outlined,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text('Оголошення',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Знайдіть партнера для в\'язки або цуценят улюбленої породи у розділі оголошень.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEvent {
  const _UpcomingEvent(
      {required this.title,
      required this.pet,
      required this.date,
      required this.isOverdue});
  final String title;
  final Pet pet;
  final DateTime date;
  final bool isOverdue;

  String get petName => pet.name;
}

class _UpcomingEventsCard extends StatefulWidget {
  const _UpcomingEventsCard({required this.pets});
  final List<Pet> pets;

  @override
  State<_UpcomingEventsCard> createState() => _UpcomingEventsCardState();
}

class _UpcomingEventsCardState extends State<_UpcomingEventsCard> {
  final _medRepo = MedicationRepository();
  List<_UpcomingEvent> _events = [];
  bool _loaded = false;

  @override
  void didUpdateWidget(_UpcomingEventsCard old) {
    super.didUpdateWidget(old);
    if (old.pets != widget.pets) _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.pets.isEmpty) {
      if (mounted) {
        setState(() {
          _events = [];
          _loaded = true;
        });
      }
      return;
    }

    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 5));
    final events = <_UpcomingEvent>[];

    for (final pet in widget.pets) {
      try {
        final meds = await _medRepo.getMedications(pet.id);
        for (final med in meds) {
          final d = med.nextDoseDate;
          if (d == null) {
            continue;
          }
          if (d.isBefore(now.subtract(const Duration(days: 1))) &&
              !med.nextDoseOverdue) {
            continue;
          }
          if (d.isAfter(threshold)) {
            continue;
          }
          events.add(_UpcomingEvent(
            title: med.name,
            pet: pet,
            date: d,
            isOverdue: med.nextDoseOverdue,
          ));
        }
      } catch (_) {}
    }

    events.sort((a, b) => a.date.compareTo(b.date));

    if (mounted) {
      setState(() {
        _events = events;
        _loaded = true;
      });
    }
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return 'Протерміновано';
    if (diff == 0) return 'Сьогодні';
    if (diff == 1) return 'Завтра';
    return 'Через $diff дн.';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _events.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text('Найближчі події',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ..._events.map((e) {
              final overdue = e.isOverdue;
              final color = overdue ? AppTheme.danger : AppTheme.warning;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      MedicationsScreen(petId: e.pet.id, petName: e.pet.name),
                )),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          overdue
                              ? Icons.warning_amber_rounded
                              : Icons.medication_outlined,
                          size: 20,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${e.petName} · ${_formatDate(e.date)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: overdue
                                        ? color
                                        : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(e.date),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: color),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            }),
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
          leading: PetAvatar(name: pet.name, avatarUrl: pet.avatarUrl),
          title: Text(pet.name,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              Text('${pet.speciesLabel} · ${pet.breed ?? 'Породу не вказано'}'),
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
