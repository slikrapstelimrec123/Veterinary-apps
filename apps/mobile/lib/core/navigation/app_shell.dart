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
import '../../features/pets/screens/pet_profile_screen.dart';
import '../../features/pet_transfer/screens/incoming_transfers_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/visit_records/data/visit_record_repository.dart';
import '../../features/visit_records/screens/add_visit_record_screen.dart';
import '../../features/visit_records/screens/visit_record_details_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/pet_avatar.dart';
import '../auth/auth_state.dart';
import '../config/supabase_config.dart';
import '../data/app_data_events.dart';
import '../notifications/local_notification_service.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  late final PageController _pageController = PageController();
  final _tabVersions = List<int>.filled(5, 0);
  final Set<int> _staleTabs = <int>{};
  RealtimeChannel? _notificationChannel;
  RealtimeChannel? _transferChannel;
  final notificationRepository = NotificationRepository();
  late Future<int> unreadFuture = notificationRepository.getUnreadCount();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppDataEvents.revision.addListener(_refreshAllData);
    LocalNotificationService.instance.tappedPayload
        .addListener(_handleSystemNotificationTap);
    _configureSystemNotifications();
  }

  Future<void> _handleSystemNotificationTap() async {
    final payload = LocalNotificationService.instance.tappedPayload.value;
    if (payload == null || payload.isEmpty || !mounted) return;
    LocalNotificationService.instance.tappedPayload.value = null;

    if (payload.startsWith('visit:')) {
      final parts = payload.split(':');
      final recordId = parts.length > 1 ? parts[1] : null;
      if (recordId != null && SupabaseConfig.isConfigured) {
        try {
          final row = await Supabase.instance.client
              .from('visit_records')
              .select('id')
              .eq('id', recordId)
              .maybeSingle();
          if (row != null && mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VisitRecordDetailsScreen(recordId: recordId),
            ));
            return;
          }
        } catch (_) {
          // An old notification can belong to an account that previously
          // used this device. RLS deliberately makes that record unavailable.
        }
      }

      // Do not open an inaccessible medical record or expose its metadata.
      return;
    }

    if (payload.startsWith('medication:') && SupabaseConfig.isConfigured) {
      final parts = payload.split(':');
      final medicationId = parts.length > 1 ? parts[1] : null;
      if (medicationId != null) {
        try {
          final row = await Supabase.instance.client
              .from('pet_medications')
              .select('pet_id,pets(name)')
              .eq('id', medicationId)
              .maybeSingle();
          final petId = row?['pet_id'] as String?;
          final pet = row?['pets'] as Map<String, dynamic>?;
          if (petId != null && mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MedicationsScreen(
                petId: petId,
                petName: pet?['name'] as String? ?? 'Тварина',
              ),
            ));
            return;
          }
        } catch (_) {
          // Fall back to the inbox when the referenced record is unavailable.
        }
      }
    }

    if (payload.startsWith('transfer:')) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const IncomingTransfersScreen(),
      ));
      return;
    }

    if (mounted) {
      setState(() {
        _index = 3;
        _tabVersions[3]++;
        unreadFuture = notificationRepository.getUnreadCount();
      });
    }
  }

  void _refreshAllData() {
    if (!mounted) return;
    setState(() {
      // The inbox refreshes its own list after read actions. Replacing that
      // tab here would dispose it before it can open the tapped destination.
      if (_index != 3) {
        _tabVersions[_index]++;
      }
      _staleTabs
        ..clear()
        ..addAll(
          List<int>.generate(_tabVersions.length, (index) => index)
              .where((index) => index != _index),
        );
      unreadFuture = notificationRepository.getUnreadCount();
    });
  }

  void _selectTab(int value) {
    if (value == _index && !_staleTabs.contains(value)) return;
    setState(() {
      _index = value;
      if (_staleTabs.remove(value)) {
        _tabVersions[value]++;
      }
      if (value == 3) {
        unreadFuture = notificationRepository.getUnreadCount();
      }
    });
    if (_pageController.hasClients && _pageController.page?.round() != value) {
      _pageController.animateToPage(
        value,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
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
    // iOS and Android keep scheduled local notifications after logout. Clear
    // schedules from any previous session before rebuilding the current
    // owner's reminders from RLS-protected data.
    await LocalNotificationService.instance.cancelAll();
    await _restoreScheduledReminders();

    _notificationChannel = client
        .channel('mobile-notifications-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final notification = AppNotification.fromJson(payload.newRecord);
            // Reminder rows appear in the in-app inbox immediately, while the
            // operating system alert is scheduled for its actual due time.
            if (notification.type != 'medication_reminder' &&
                notification.type != 'next_visit_recommended' &&
                notification.type != 'pet_transfer_request') {
              LocalNotificationService.instance.show(notification);
            }
            if (mounted) {
              _tabVersions[3]++;
              refreshUnreadCount();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _refreshAllData(),
        )
        .subscribe();

    _transferChannel = client
        .channel('mobile-pet-transfers-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'pet_transfers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'to_user_id',
            value: user.id,
          ),
          callback: (payload) {
            final transferId = payload.newRecord['id'] as String?;
            if (transferId != null) {
              LocalNotificationService.instance.showTransferRequest(transferId);
            }
            _refreshAllData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pet_transfers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'from_user_id',
            value: user.id,
          ),
          callback: (_) {
            _refreshAllData();
            _resyncAllReminders();
          },
        )
        .subscribe();
  }

  Future<void> _resyncAllReminders() async {
    await LocalNotificationService.instance.cancelAll();
    await _restoreScheduledReminders();
  }

  Future<void> _restoreScheduledReminders() async {
    try {
      final pets = await PetRepository().getPets();
      for (final pet in pets) {
        if (pet.birthDate != null) {
          await LocalNotificationService.instance.scheduleBirthdayReminder(
            petId: pet.id,
            petName: pet.name,
            birthDate: pet.birthDate!,
          );
        }
        final medications = await MedicationRepository().getMedications(pet.id);
        for (final medication in medications) {
          final dueDate = medication.nextDoseDate;
          if (medication.reminderEnabled && dueDate != null) {
            await LocalNotificationService.instance.scheduleMedicationReminder(
              medicationId: medication.id,
              medicationName: medication.name,
              petName: pet.name,
              dueDate: dueDate,
            );
          } else {
            await LocalNotificationService.instance
                .cancelMedicationReminder(medication.id);
          }
        }

        final visits =
            await VisitRecordRepository().getVisitRecordsForPet(pet.id);
        for (final visit in visits) {
          final dueDate = visit.nextVisitDate;
          if (visit.nextVisitRecommended && dueDate != null) {
            await LocalNotificationService.instance.scheduleVisitReminder(
              visitRecordId: visit.id,
              petName: pet.name,
              dueDate: dueDate,
            );
          }
        }
      }
    } catch (_) {
      // Reminder synchronization must never prevent the app from opening.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppDataEvents.revision.removeListener(_refreshAllData);
    LocalNotificationService.instance.tappedPayload
        .removeListener(_handleSystemNotificationTap);
    final channel = _notificationChannel;
    if (channel != null && SupabaseConfig.isConfigured) {
      Supabase.instance.client.removeChannel(channel);
    }
    final transferChannel = _transferChannel;
    if (transferChannel != null && SupabaseConfig.isConfigured) {
      Supabase.instance.client.removeChannel(transferChannel);
    }
    _pageController.dispose();
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
          onOpenCalendar: () => _selectTab(1),
          onOpenAnnouncements: () => _selectTab(2)),
      _EventsCalendarTab(key: ValueKey('calendar-${_tabVersions[1]}')),
      AnnouncementsScreen(key: ValueKey('announcements-${_tabVersions[2]}')),
      NotificationsScreen(key: ValueKey('notifications-${_tabVersions[3]}')),
      SettingsScreen(key: ValueKey('settings-${_tabVersions[4]}')),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (value) {
          if (value != _index) _selectTab(value);
        },
        children: tabs,
      ),
      bottomNavigationBar: FutureBuilder<int>(
        future: unreadFuture,
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return NavigationBar(
            selectedIndex: _index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: _selectTab,
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.pets_outlined), label: 'Home'),
              const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
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
  const HomeScreen({
    super.key,
    required this.onOpenCalendar,
    required this.onOpenAnnouncements,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenAnnouncements;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repository = PetRepository();
  final visitRepository = VisitRecordRepository();
  final medicationRepository = MedicationRepository();
  late Future<_HomeData> homeFuture = _loadHomeData();
  String? _selectedPetId;

  void refresh() {
    setState(() => homeFuture = _loadHomeData());
  }

  Future<_HomeData> _loadHomeData() async {
    final pets = await repository.getPets();
    final perPetFocus = await Future.wait(pets.map(_loadPetFocus));
    final focusItems = perPetFocus.expand((result) => result.items).toList();

    focusItems.sort((left, right) => left.date.compareTo(right.date));
    return _HomeData(
      pets: pets,
      focusItems: focusItems,
      focusDataComplete: perPetFocus.every((result) => result.isComplete),
    );
  }

  Future<_PetFocusData> _loadPetFocus(Pet pet) async {
    final results = await Future.wait([
      _loadMedicationFocus(pet),
      _loadVisitFocus(pet),
    ]);
    return _PetFocusData(
      items: results
          .whereType<List<_HomeFocusItem>>()
          .expand((items) => items)
          .toList(growable: false),
      isComplete: results.every((items) => items != null),
    );
  }

  Future<List<_HomeFocusItem>?> _loadMedicationFocus(Pet pet) async {
    try {
      final medications = await medicationRepository.getMedications(pet.id);
      return medications
          .where((medication) =>
              medication.reminderEnabled && medication.nextDoseDate != null)
          .map(
            (medication) => _HomeFocusItem(
              type: _HomeFocusType.medication,
              pet: pet,
              title: 'Препарат «${medication.name}»',
              date: medication.nextDoseDate!,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      // One unavailable section must not hide the rest of the home screen.
      return null;
    }
  }

  Future<List<_HomeFocusItem>?> _loadVisitFocus(Pet pet) async {
    try {
      final visits = await visitRepository.getVisitRecordsForPet(pet.id);
      return visits
          .where(
            (visit) =>
                visit.nextVisitRecommended && visit.nextVisitDate != null,
          )
          .map(
            (visit) => _HomeFocusItem(
              type: _HomeFocusType.visit,
              pet: pet,
              title: 'Запланований повторний прийом',
              date: visit.nextVisitDate!,
              visitRecordId: visit.id,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      // Keep other owner-created medical data available.
      return null;
    }
  }

  Future<void> addPet() async {
    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddPetScreen()));
    if (result != null) refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).currentUser;

    return FutureBuilder<_HomeData>(
      future: homeFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _HomeData();
        final pets = data.pets;
        final Pet? selectedPet = pets.isEmpty
            ? null
            : pets.firstWhere(
                (pet) => pet.id == _selectedPetId,
                orElse: () => pets.first,
              );

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
                _HomeFocusCard(
                  pets: pets,
                  selectedPet: selectedPet!,
                  focusItems: data.focusItems,
                  focusDataComplete: data.focusDataComplete,
                  onPetSelected: (petId) =>
                      setState(() => _selectedPetId = petId),
                  onOpenCalendar: widget.onOpenCalendar,
                  onOpenItem: (item) async {
                    if (item.type == _HomeFocusType.medication) {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MedicationsScreen(
                          petId: item.pet.id,
                          petName: item.pet.name,
                        ),
                      ));
                    } else if (item.visitRecordId != null) {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => VisitRecordDetailsScreen(
                          recordId: item.visitRecordId!,
                        ),
                      ));
                    }
                    if (mounted) refresh();
                  },
                  onOpenPet: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PetProfileScreen(petId: selectedPet.id),
                      ),
                    );
                    if (result != null && mounted) refresh();
                  },
                  onRefresh: refresh,
                ),
              ],
              const SizedBox(height: 12),
              _AnnouncementsCard(onTap: widget.onOpenAnnouncements),
            ],
          ],
        );
      },
    );
  }
}

class _HomeData {
  const _HomeData({
    this.pets = const [],
    this.focusItems = const [],
    this.focusDataComplete = true,
  });

  final List<Pet> pets;
  final List<_HomeFocusItem> focusItems;
  final bool focusDataComplete;
}

class _PetFocusData {
  const _PetFocusData({
    required this.items,
    required this.isComplete,
  });

  final List<_HomeFocusItem> items;
  final bool isComplete;
}

enum _HomeFocusType { medication, visit }

class _HomeFocusItem {
  const _HomeFocusItem({
    required this.type,
    required this.pet,
    required this.title,
    required this.date,
    this.visitRecordId,
  });

  final _HomeFocusType type;
  final Pet pet;
  final String title;
  final DateTime date;
  final String? visitRecordId;
}

class _HomeFocusCard extends StatelessWidget {
  const _HomeFocusCard({
    required this.pets,
    required this.selectedPet,
    required this.focusItems,
    required this.focusDataComplete,
    required this.onPetSelected,
    required this.onOpenCalendar,
    required this.onOpenItem,
    required this.onOpenPet,
    required this.onRefresh,
  });

  final List<Pet> pets;
  final Pet selectedPet;
  final List<_HomeFocusItem> focusItems;
  final bool focusDataComplete;
  final ValueChanged<String> onPetSelected;
  final VoidCallback onOpenCalendar;
  final ValueChanged<_HomeFocusItem> onOpenItem;
  final VoidCallback onOpenPet;
  final VoidCallback onRefresh;

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  String _dateLabel(DateTime value) {
    final today = _day(DateTime.now());
    final date = _day(value);
    final days = date.difference(today).inDays;
    if (days < 0) return 'Протерміновано';
    if (days == 0) return 'Сьогодні';
    if (days == 1) return 'Завтра';
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = _day(DateTime.now());
    final monthEnd = today.add(const Duration(days: 30));
    final monthItems = focusItems
        .where(
          (item) =>
              item.pet.id == selectedPet.id &&
              !_day(item.date).isBefore(today) &&
              !_day(item.date).isAfter(monthEnd),
        )
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pets.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: pets
                      .map(
                        (pet) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: pet.id == selectedPet.id,
                            onSelected: (_) => onPetSelected(pet.id),
                            avatar: PetAvatar(
                              name: pet.name,
                              avatarUrl: pet.avatarUrl,
                              size: 24,
                            ),
                            label: Text(pet.name),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                PetAvatar(
                  name: selectedPet.name,
                  avatarUrl: selectedPet.avatarUrl,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !focusDataComplete && monthItems.isEmpty
                            ? 'Не вдалося оновити план'
                            : 'План на 30 днів для ${selectedPet.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !focusDataComplete && monthItems.isEmpty
                            ? 'Перевірте з’єднання та спробуйте ще раз.'
                            : monthItems.isEmpty
                                ? 'Запланованих подій на найближчий місяць немає.'
                                : 'Заплановано подій: ${monthItems.length}.',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!focusDataComplete && monthItems.isEmpty)
                  const Icon(Icons.sync_problem_outlined,
                      color: AppTheme.danger)
                else
                  IconButton(
                    onPressed: onOpenCalendar,
                    tooltip: 'Відкрити календар',
                    icon: const Icon(Icons.calendar_month_outlined),
                    color: AppTheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (monthItems.isNotEmpty)
              ...monthItems.map(
                (item) {
                  final isToday = _day(item.date) == today;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => onOpenItem(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  item.type == _HomeFocusType.medication
                                      ? Icons.medication_outlined
                                      : Icons.medical_information_outlined,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _dateLabel(item.date),
                                      style: TextStyle(
                                        color: isToday
                                            ? AppTheme.danger
                                            : AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              Text(
                focusDataComplete
                    ? 'Додавайте препарати та повторні прийоми — '
                        'події на наступні 30 днів з’являтимуться тут.'
                    : 'Медична картка доступна, але план потребує оновлення.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  if (!focusDataComplete)
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Оновити'),
                    ),
                  TextButton.icon(
                    onPressed: onOpenPet,
                    icon: const Icon(Icons.pets_outlined, size: 18),
                    label: const Text('Медична картка'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCalendarScreen extends StatefulWidget {
  const _PetCalendarScreen({
    required this.pet,
    required this.items,
    required this.onOpenItem,
  });

  final Pet pet;
  final List<_HomeFocusItem> items;
  final ValueChanged<_HomeFocusItem> onOpenItem;

  @override
  State<_PetCalendarScreen> createState() => _PetCalendarScreenState();
}

class _PetCalendarScreenState extends State<_PetCalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  List<_HomeFocusItem> get _selectedItems => widget.items
      .where((item) => _day(item.date) == _selectedDate)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Календар',
      subtitle: widget.pet.name,
      children: [
        Card(
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (date) => setState(() => _selectedDate = _day(date)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_selectedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'На цей день подій немає.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ..._selectedItems.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(
                  item.type == _HomeFocusType.medication
                      ? Icons.medication_outlined
                      : Icons.medical_information_outlined,
                  color: AppTheme.primary,
                ),
                title: Text(item.title),
                subtitle: Text(_dateLabel(item.date)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onOpenItem(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _EventsCalendarTab extends StatefulWidget {
  const _EventsCalendarTab({super.key});

  @override
  State<_EventsCalendarTab> createState() => _EventsCalendarTabState();
}

class _EventsCalendarTabState extends State<_EventsCalendarTab> {
  final _petRepository = PetRepository();
  final _medicationRepository = MedicationRepository();
  final _visitRepository = VisitRecordRepository();
  late Future<List<_HomeFocusItem>> _events = _loadEvents();
  List<Pet> _pets = const [];
  DateTime _selectedDate = DateTime.now();

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  Future<List<_HomeFocusItem>> _loadEvents() async {
    final pets = await _petRepository.getPets();
    _pets = pets;
    final results = await Future.wait(pets.map((pet) async {
      final items = <_HomeFocusItem>[];
      try {
        final medications = await _medicationRepository.getMedications(pet.id);
        items.addAll(medications
            .where((item) => item.reminderEnabled && item.nextDoseDate != null)
            .map((item) => _HomeFocusItem(
                  type: _HomeFocusType.medication,
                  pet: pet,
                  title: 'Препарат «${item.name}»',
                  date: item.nextDoseDate!,
                )));
      } catch (_) {}
      try {
        final visits = await _visitRepository.getVisitRecordsForPet(pet.id);
        items.addAll(visits
            .where((item) =>
                item.nextVisitRecommended && item.nextVisitDate != null)
            .map((item) => _HomeFocusItem(
                  type: _HomeFocusType.visit,
                  pet: pet,
                  title: 'Запланований повторний прийом',
                  date: item.nextVisitDate!,
                  visitRecordId: item.id,
                )));
      } catch (_) {}
      return items;
    }));
    return results.expand((items) => items).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _openItem(_HomeFocusItem item) async {
    if (item.type == _HomeFocusType.medication) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MedicationsScreen(
          petId: item.pet.id,
          petName: item.pet.name,
        ),
      ));
    } else if (item.visitRecordId != null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VisitRecordDetailsScreen(recordId: item.visitRecordId!),
      ));
    }
  }

  Future<void> _addEvent() async {
    if (_pets.isEmpty) return;
    Pet pet = _pets.first;
    if (_pets.length > 1) {
      final selected = await showModalBottomSheet<Pet>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Оберіть тварину',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              ..._pets.map((item) => ListTile(
                    leading: PetAvatar(
                        name: item.name, avatarUrl: item.avatarUrl, size: 40),
                    title: Text(item.name),
                    subtitle: Text(item.speciesLabel),
                    onTap: () => Navigator.pop(context, item),
                  )),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      pet = selected;
    }
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddVisitRecordScreen(
        petId: pet.id,
        petName: pet.name,
      ),
    ));
    if (result != null && mounted) {
      setState(() => _events = _loadEvents());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HomeFocusItem>>(
      future: _events,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <_HomeFocusItem>[];
        final today = _day(DateTime.now());
        final monthEnd = today.add(const Duration(days: 30));
        final upcoming = events.where((item) {
          final date = _day(item.date);
          return !date.isBefore(today) && !date.isAfter(monthEnd);
        }).toList(growable: false);
        return AppScaffold(
          title: 'Календар подій',
          subtitle: 'Запланований догляд за вашими тваринами.',
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(
                message: 'Не вдалося завантажити події.',
                onRetry: () => setState(() => _events = _loadEvents()),
              )
            else ...[
              FilledButton.icon(
                onPressed: _addEvent,
                icon: const Icon(Icons.add),
                label: const Text('Додати подію'),
              ),
              const SizedBox(height: 12),
              Card(
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: (date) =>
                      setState(() => _selectedDate = _day(date)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Найближчі події на 30 днів',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('На найближчі 30 днів подій немає.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                )
              else
                ...upcoming.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(
                        item.type == _HomeFocusType.medication
                            ? Icons.medication_outlined
                            : Icons.medical_information_outlined,
                        color: AppTheme.primary,
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                          '${item.pet.name} · ${item.date.day.toString().padLeft(2, '0')}.${item.date.month.toString().padLeft(2, '0')}.${item.date.year}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openItem(item),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _AnnouncementsCard extends StatelessWidget {
  const _AnnouncementsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }
}
