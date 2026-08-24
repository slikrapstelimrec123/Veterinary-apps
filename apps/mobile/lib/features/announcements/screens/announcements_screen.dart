import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../../../shared/widgets/pet_avatar.dart';
import '../../billing/data/billing_repository.dart';
import '../../billing/domain/owner_plan.dart';
import '../../billing/screens/listing_packages_screen.dart';
import '../../pets/data/pet_repository.dart';
import '../../pets/domain/pet.dart';
import '../data/announcement_repository.dart';
import '../domain/announcement_filter_options.dart';
import '../domain/breeding_announcement.dart';
import '../domain/community_announcement.dart';
import '../domain/sale_announcement.dart';
import 'add_breeding_announcement_screen.dart';
import 'add_sale_announcement_screen.dart';
import 'community_announcement_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 6, vsync: this);
  final _billingRepository = BillingRepository();
  RealtimeChannel? _channel;
  Map<String, PublicationAccess>? _publicationAccess;
  bool _publicationUsageLoading = true;
  final Map<String, int> _versions = {
    'breeding': 0,
    'sale': 0,
    'event': 0,
    'service': 0,
    'offer': 0,
    'mine': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadPublicationUsage();
    if (!SupabaseConfig.useMockData) {
      final client = Supabase.instance.client;
      _channel = client
          .channel('mobile-announcements')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'announcements',
            callback: (payload) {
              if (!mounted) return;
              final type = (payload.newRecord['announcement_type'] ??
                      payload.oldRecord['announcement_type'])
                  ?.toString();
              setState(() {
                if (type != null && _versions.containsKey(type)) {
                  _versions[type] = _versions[type]! + 1;
                }
                _versions['mine'] = _versions['mine']! + 1;
              });
              unawaited(_loadPublicationUsage());
            },
          )
          .subscribe();
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null && SupabaseConfig.isConfigured) {
      Supabase.instance.client.removeChannel(channel);
    }
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Оголошення',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          AnimatedBuilder(
            animation: _tab,
            builder: (context, _) => _tab.index == 5
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: _createCurrent,
                    icon: const Icon(Icons.add),
                    tooltip: 'Додати оголошення',
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Пошук партнера'),
            Tab(text: 'Цуценята'),
            Tab(text: 'Події'),
            Tab(text: 'Послуги'),
            Tab(text: 'Пропозиції'),
            Tab(text: 'Мої'),
          ],
        ),
      ),
      body: Column(
        children: [
          _PublicationUsageBanner(
            access: _publicationAccess,
            loading: _publicationUsageLoading,
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BreedingTab(
                  key: ValueKey('breeding-${_versions['breeding']}'),
                ),
                _SaleTab(key: ValueKey('sale-${_versions['sale']}')),
                CommunityAnnouncementTab(
                  key: ValueKey('event-${_versions['event']}'),
                  type: CommunityAnnouncementType.event,
                ),
                CommunityAnnouncementTab(
                  key: ValueKey('service-${_versions['service']}'),
                  type: CommunityAnnouncementType.service,
                ),
                CommunityAnnouncementTab(
                  key: ValueKey('offer-${_versions['offer']}'),
                  type: CommunityAnnouncementType.offer,
                ),
                _MyAnnouncementsTab(
                  key: ValueKey('mine-${_versions['mine']}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPublicationUsage() async {
    try {
      final accesses = await Future.wait([
        _billingRepository.getPublicationAccess('breeding'),
        _billingRepository.getPublicationAccess('sale'),
      ]);
      if (!mounted) return;
      setState(() {
        _publicationAccess = {
          'breeding': accesses[0],
          'sale': accesses[1],
        };
        _publicationUsageLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _publicationUsageLoading = false);
    }
  }

  Future<void> _createCurrent() async {
    final index = _tab.index;
    final publicationType = switch (index) {
      0 => 'breeding',
      1 => 'sale',
      2 => 'event',
      3 => 'service',
      4 => 'offer',
      _ => null,
    };
    if (publicationType == null) return;

    String? listingCreditId;
    try {
      final access =
          await BillingRepository().getPublicationAccess(publicationType);
      if (!access.allowed) {
        if (!mounted) return;
        listingCreditId = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => ListingPackagesScreen(
              announcementType: publicationType,
            ),
          ),
        );
        if (listingCreditId == null || !mounted) return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не вдалося перевірити доступ до публікації. Спробуйте ще раз.',
          ),
        ),
      );
      return;
    }

    bool? saved;
    if (index == 0 || index == 1) {
      final pet = await _selectPet();
      if (pet == null || !mounted) return;
      saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => index == 0
              ? AddBreedingAnnouncementScreen(
                  pet: pet,
                  listingCreditId: listingCreditId,
                )
              : AddSaleAnnouncementScreen(
                  pet: pet,
                  listingCreditId: listingCreditId,
                ),
        ),
      );
    } else if (index >= 2 && index <= 4) {
      if (!mounted) return;
      final type = CommunityAnnouncementType.values[index - 2];
      saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CommunityAnnouncementFormScreen(
            type: type,
            listingCreditId: listingCreditId,
          ),
        ),
      );
    }
    if (saved == true && mounted) {
      final type = switch (index) {
        0 => 'breeding',
        1 => 'sale',
        2 => 'event',
        3 => 'service',
        4 => 'offer',
        _ => 'mine',
      };
      setState(() {
        _versions[type] = _versions[type]! + 1;
        _versions['mine'] = _versions['mine']! + 1;
      });
      unawaited(_loadPublicationUsage());
    }
  }

  Future<Pet?> _selectPet() async {
    List<Pet> pets;
    try {
      pets = await PetRepository().getPets();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося завантажити тварин.')),
        );
      }
      return null;
    }
    if (!mounted) return null;
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Спочатку додайте тварину до свого профілю.'),
        ),
      );
      return null;
    }
    return showModalBottomSheet<Pet>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Text(
              'Оберіть тварину',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ...pets.map(
              (pet) => ListTile(
                leading: PetAvatar(
                  name: pet.name,
                  avatarUrl: pet.avatarUrl,
                  size: 44,
                ),
                title: Text(pet.name),
                subtitle: Text(pet.breed ?? pet.speciesLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, pet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationUsageBanner extends StatelessWidget {
  const _PublicationUsageBanner({
    required this.access,
    required this.loading,
  });

  final Map<String, PublicationAccess>? access;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && access == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (access == null) return const SizedBox.shrink();

    final breeding = access?['breeding']?.remaining;
    final sale = access?['sale']?.remaining;
    String remaining(int? value) =>
        value == null ? 'Без обмежень' : value.toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Залишок оголошень цього місяця',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Пошук партнера: ${remaining(breeding)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Продаж: ${remaining(sale)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Breeding Tab ─────────────────────────────────────────────────────────────

class _BreedingTab extends StatefulWidget {
  const _BreedingTab({super.key});

  @override
  State<_BreedingTab> createState() => _BreedingTabState();
}

class _BreedingTabState extends State<_BreedingTab> {
  final _repo = AnnouncementRepository();
  late Future<List<BreedingAnnouncement>> _future;
  late Future<PetAnnouncementFilterOptions> _filterOptions;
  String? _selectedBreed;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _filterOptions = _repo.getPetAnnouncementFilterOptions('breeding');
    _load();
  }

  void _load() {
    setState(() {
      _future = _repo.getBreedingAnnouncements(
          breed: _selectedBreed, city: _selectedCity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PetAnnouncementFilterOptions>(
      future: _filterOptions,
      builder: (context, filtersSnapshot) {
        final filters = filtersSnapshot.data ??
            const PetAnnouncementFilterOptions(breeds: [], cities: []);
        return Column(
          children: [
            _BreedFilter(
              breeds: filters.breeds,
              selected: _selectedBreed,
              onChanged: (b) {
                setState(() => _selectedBreed = b);
                _load();
              },
            ),
            _BreedFilter(
              breeds: filters.cities,
              selected: _selectedCity,
              onChanged: (c) {
                setState(() => _selectedCity = c);
                _load();
              },
              allLabel: 'Всі міста',
            ),
            Expanded(
              child: FutureBuilder<List<BreedingAnnouncement>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Оголошень не знайдено',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _BreedingCard(
                      item: items[i],
                      onTap: () {
                        unawaited(_repo.recordAnnouncementView(items[i].id));
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _BreedingDetailScreen(item: items[i]),
                        ));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Sale Tab ─────────────────────────────────────────────────────────────────

class _SaleTab extends StatefulWidget {
  const _SaleTab({super.key});

  @override
  State<_SaleTab> createState() => _SaleTabState();
}

class _SaleTabState extends State<_SaleTab> {
  final _repo = AnnouncementRepository();
  late Future<List<SaleAnnouncement>> _future;
  late Future<PetAnnouncementFilterOptions> _filterOptions;
  String? _selectedBreed;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _filterOptions = _repo.getPetAnnouncementFilterOptions('sale');
    _load();
  }

  void _load() {
    setState(() {
      _future = _repo.getSaleAnnouncements(
          breed: _selectedBreed, city: _selectedCity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PetAnnouncementFilterOptions>(
      future: _filterOptions,
      builder: (context, filtersSnapshot) {
        final filters = filtersSnapshot.data ??
            const PetAnnouncementFilterOptions(breeds: [], cities: []);
        return Column(
          children: [
            _BreedFilter(
              breeds: filters.breeds,
              selected: _selectedBreed,
              onChanged: (b) {
                setState(() => _selectedBreed = b);
                _load();
              },
            ),
            _BreedFilter(
              breeds: filters.cities,
              selected: _selectedCity,
              onChanged: (c) {
                setState(() => _selectedCity = c);
                _load();
              },
              allLabel: 'Всі міста',
            ),
            Expanded(
              child: FutureBuilder<List<SaleAnnouncement>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Оголошень не знайдено',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _SaleCard(
                      item: items[i],
                      onTap: () {
                        unawaited(_repo.recordAnnouncementView(items[i].id));
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _SaleDetailScreen(item: items[i]),
                        ));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── My Announcements Tab ─────────────────────────────────────────────────────

class _MyAnnouncementsTab extends StatefulWidget {
  const _MyAnnouncementsTab({super.key});

  @override
  State<_MyAnnouncementsTab> createState() => _MyAnnouncementsTabState();
}

class _MyAnnouncementsTabState extends State<_MyAnnouncementsTab>
    with SingleTickerProviderStateMixin {
  final _repo = AnnouncementRepository();
  late final TabController _sub = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  Future<List<SaleAnnouncement>> _mySale(bool active) =>
      _repo.getMySaleAnnouncements(active: active);

  Future<List<BreedingAnnouncement>> _myBreeding(bool active) =>
      _repo.getMyBreedingAnnouncements(active: active);

  Future<List<CommunityAnnouncement>> _myCommunity(bool active) =>
      _repo.getMyCommunityAnnouncements(active: active);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _sub,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Активні'), Tab(text: 'Неактивні')],
        ),
        Expanded(
          child: TabBarView(
            controller: _sub,
            children: [
              _MyAnnouncementsList(
                  saleFuture: _mySale(true),
                  breedingFuture: _myBreeding(true),
                  communityFuture: _myCommunity(true),
                  active: true,
                  onToggle: () => setState(() {})),
              _MyAnnouncementsList(
                  saleFuture: _mySale(false),
                  breedingFuture: _myBreeding(false),
                  communityFuture: _myCommunity(false),
                  active: false,
                  onToggle: () => setState(() {})),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyAnnouncementsList extends StatelessWidget {
  const _MyAnnouncementsList({
    required this.saleFuture,
    required this.breedingFuture,
    required this.communityFuture,
    required this.active,
    required this.onToggle,
  });

  final Future<List<SaleAnnouncement>> saleFuture;
  final Future<List<BreedingAnnouncement>> breedingFuture;
  final Future<List<CommunityAnnouncement>> communityFuture;
  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([saleFuture, breedingFuture, communityFuture]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = (snap.data?[0] as List<SaleAnnouncement>?) ?? [];
        final breedings = (snap.data?[1] as List<BreedingAnnouncement>?) ?? [];
        final community = (snap.data?[2] as List<CommunityAnnouncement>?) ?? [];

        if (sales.isEmpty && breedings.isEmpty && community.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? Icons.campaign_outlined : Icons.archive_outlined,
                    size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                Text(
                  active
                      ? 'Немає активних оголошень'
                      : 'Немає архівних оголошень',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (sales.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Цуценята',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              ...sales.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MyAnnouncementCard(
                      title: s.breed,
                      subtitle: '${s.puppyName} · ${s.priceLabel}',
                      location: s.location,
                      createdAt: s.createdAt,
                      active: s.isActive,
                      viewCount: s.viewCount,
                      icon: Icons.pets,
                      photoUrl: s.petAvatarUrl,
                      onToggle: () async {
                        await AnnouncementRepository().toggleSaleActive(s.id);
                        onToggle();
                      },
                      onDelete: () async {
                        await AnnouncementRepository()
                            .deleteSaleAnnouncement(s.id);
                        onToggle();
                      },
                      onEdit: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (_) => _EditSaleScreen(
                            item: s,
                            onDelete: () async {
                              await AnnouncementRepository()
                                  .deleteSaleAnnouncement(s.id);
                              onToggle();
                            },
                            onToggle: () async {
                              await AnnouncementRepository()
                                  .toggleSaleActive(s.id);
                              onToggle();
                            }),
                      ))
                          .then((saved) {
                        if (saved == true) onToggle();
                      }),
                    ),
                  )),
            ],
            if (breedings.isNotEmpty) ...[
              Padding(
                padding:
                    EdgeInsets.only(top: sales.isNotEmpty ? 8 : 0, bottom: 8),
                child: const Text('Пошук партнера',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              ...breedings.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MyAnnouncementCard(
                      title: b.breed,
                      subtitle: '${b.myDogName} · ${b.genderLabel}',
                      location: b.location,
                      createdAt: b.createdAt,
                      active: b.isActive,
                      viewCount: b.viewCount,
                      icon: Icons.favorite_outlined,
                      photoUrl: b.petAvatarUrl,
                      onToggle: () async {
                        await AnnouncementRepository()
                            .toggleBreedingActive(b.id);
                        onToggle();
                      },
                      onDelete: () async {
                        await AnnouncementRepository()
                            .deleteBreedingAnnouncement(b.id);
                        onToggle();
                      },
                      onEdit: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (_) => _EditBreedingScreen(
                            item: b,
                            onDelete: () async {
                              await AnnouncementRepository()
                                  .deleteBreedingAnnouncement(b.id);
                              onToggle();
                            },
                            onToggle: () async {
                              await AnnouncementRepository()
                                  .toggleBreedingActive(b.id);
                              onToggle();
                            }),
                      ))
                          .then((saved) {
                        if (saved == true) onToggle();
                      }),
                    ),
                  )),
            ],
            if (community.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: sales.isNotEmpty || breedings.isNotEmpty ? 8 : 0,
                  bottom: 8,
                ),
                child: const Text(
                  'Інші оголошення',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              ...community.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MyAnnouncementCard(
                    title: item.title,
                    subtitle: '${item.type.label} · ${item.subtitle}',
                    location: item.address,
                    createdAt: item.createdAt,
                    active: item.isActive,
                    viewCount: item.viewCount,
                    icon: switch (item.type) {
                      CommunityAnnouncementType.event => Icons.event_outlined,
                      CommunityAnnouncementType.service =>
                        Icons.design_services_outlined,
                      CommunityAnnouncementType.offer =>
                        Icons.local_offer_outlined,
                    },
                    photoUrl: item.photoUrl,
                    onToggle: () async {
                      await AnnouncementRepository()
                          .toggleCommunityActive(item.id);
                      onToggle();
                    },
                    onDelete: () async {
                      await AnnouncementRepository()
                          .deleteCommunityAnnouncement(item.id);
                      onToggle();
                    },
                    onEdit: () => Navigator.of(context)
                        .push<bool>(
                      MaterialPageRoute(
                        builder: (_) => CommunityAnnouncementFormScreen(
                          type: item.type,
                          item: item,
                        ),
                      ),
                    )
                        .then((saved) {
                      if (saved == true) onToggle();
                    }),
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

class _MyAnnouncementCard extends StatelessWidget {
  const _MyAnnouncementCard({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.createdAt,
    required this.active,
    required this.viewCount,
    required this.icon,
    this.photoUrl,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final String? location;
  final DateTime createdAt;
  final bool active;
  final int viewCount;
  final IconData icon;
  final String? photoUrl;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити оголошення?'),
        content: const Text('Цю дію неможливо скасувати.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Видалити')),
        ],
      ),
    );
    if (ok == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (active ? AppTheme.primary : AppTheme.textSecondary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl?.isNotEmpty == true
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(icon,
                          color: active
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          size: 22),
                    )
                  : Icon(icon,
                      color: active ? AppTheme.primary : AppTheme.textSecondary,
                      size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (location != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                            child: Text(location!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary))),
                        const SizedBox(width: 8),
                      ],
                      Text(_daysAgo(createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(width: 8),
                      const Icon(Icons.visibility_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '$viewCount',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppTheme.primary,
              onPressed: onEdit,
              tooltip: 'Редагувати',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppTheme.danger,
              onPressed: () => _confirmDelete(context),
              tooltip: 'Видалити',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Sale Screen ─────────────────────────────────────────────────────────

class _EditSaleScreen extends StatefulWidget {
  const _EditSaleScreen(
      {required this.item, required this.onDelete, required this.onToggle});
  final SaleAnnouncement item;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  State<_EditSaleScreen> createState() => _EditSaleScreenState();
}

class _EditSaleScreenState extends State<_EditSaleScreen> {
  late final TextEditingController _breed =
      TextEditingController(text: widget.item.breed);
  late final TextEditingController _name =
      TextEditingController(text: widget.item.puppyName);
  late final TextEditingController _price =
      TextEditingController(text: widget.item.price.toString());
  late final TextEditingController _location =
      TextEditingController(text: widget.item.location ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.item.phone);
  late final TextEditingController _notes =
      TextEditingController(text: widget.item.notes ?? '');
  final _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  late String? _photoUrl = widget.item.photoUrl;
  late String? _photoStoragePath = widget.item.photoStoragePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _breed.dispose();
    _name.dispose();
    _price.dispose();
    _location.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (image != null && mounted) {
      setState(() => _selectedPhoto = image);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final price = int.tryParse(_price.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вкажіть коректну ціну оголошення.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_selectedPhoto != null) {
        final petId = widget.item.petId;
        if (petId == null) {
          throw StateError('Announcement pet is unavailable.');
        }
        _photoStoragePath = await PrivatePetStorage.uploadImage(
          petId: petId,
          category: 'announcements',
          file: File(_selectedPhoto!.path),
        );
        _photoUrl = await PrivatePetStorage.signedUrl(_photoStoragePath!);
      }
      await AnnouncementRepository()
          .updateSaleAnnouncement(
            SaleAnnouncement(
              id: widget.item.id,
              ownerName: widget.item.ownerName,
              phone: _phone.text.trim().isEmpty
                  ? widget.item.phone
                  : _phone.text.trim(),
              breed: _breed.text.trim().isEmpty
                  ? widget.item.breed
                  : _breed.text.trim(),
              puppyName: _name.text.trim().isEmpty
                  ? widget.item.puppyName
                  : _name.text.trim(),
              gender: widget.item.gender,
              birthDate: widget.item.birthDate,
              price: price,
              photoUrl: _photoUrl,
              photoStoragePath: _photoStoragePath,
              petAvatarUrl: widget.item.petAvatarUrl,
              petAvatarStoragePath: widget.item.petAvatarStoragePath,
              color: widget.item.color,
              hasVaccinations: widget.item.hasVaccinations,
              hasPedigree: widget.item.hasPedigree,
              hasChip: widget.item.hasChip,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              location:
                  _location.text.trim().isEmpty ? null : _location.text.trim(),
              createdAt: widget.item.createdAt,
              isActive: widget.item.isActive,
              ownerId: widget.item.ownerId,
              petId: widget.item.petId,
            ),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не вдалося зберегти зміни. Перевірте інтернет і спробуйте ще раз.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Редагувати оголошення',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnnouncementPhotoEditor(
            photoUrl: _photoUrl,
            selectedPhoto: _selectedPhoto,
            onPick: _isSaving ? null : _pickPhoto,
          ),
          const SizedBox(height: 16),
          _EditField(label: 'Порода', controller: _breed),
          const SizedBox(height: 12),
          _EditField(label: 'Ім\'я цуценяти', controller: _name),
          const SizedBox(height: 12),
          _EditField(
              label: 'Ціна (грн)',
              controller: _price,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _EditField(
              label: 'Телефон',
              controller: _phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          CityAutocompleteField(controller: _location, filled: true),
          const SizedBox(height: 12),
          _EditField(label: 'Примітки', controller: _notes, maxLines: 4),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Зберегти'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              widget.onToggle();
              Navigator.of(context).pop();
            },
            icon: Icon(widget.item.isActive
                ? Icons.archive_outlined
                : Icons.unarchive_outlined),
            label: Text(widget.item.isActive ? 'В архів' : 'Відновити'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Edit Breeding Screen ─────────────────────────────────────────────────────

class _EditBreedingScreen extends StatefulWidget {
  const _EditBreedingScreen(
      {required this.item, required this.onDelete, required this.onToggle});
  final BreedingAnnouncement item;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  State<_EditBreedingScreen> createState() => _EditBreedingScreenState();
}

class _EditBreedingScreenState extends State<_EditBreedingScreen> {
  late final TextEditingController _breed =
      TextEditingController(text: widget.item.breed);
  late final TextEditingController _dogName =
      TextEditingController(text: widget.item.myDogName);
  late final TextEditingController _conditions =
      TextEditingController(text: widget.item.conditions ?? '');
  late final TextEditingController _location =
      TextEditingController(text: widget.item.location ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.item.phone);
  late final TextEditingController _notes =
      TextEditingController(text: widget.item.notes ?? '');
  final _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  late String? _photoUrl = widget.item.myDogPhotoUrl;
  late String? _photoStoragePath = widget.item.photoStoragePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _breed.dispose();
    _dogName.dispose();
    _conditions.dispose();
    _location.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (image != null && mounted) {
      setState(() => _selectedPhoto = image);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);
    try {
      if (_selectedPhoto != null) {
        final petId = widget.item.petId;
        if (petId == null) {
          throw StateError('Announcement pet is unavailable.');
        }
        _photoStoragePath = await PrivatePetStorage.uploadImage(
          petId: petId,
          category: 'announcements',
          file: File(_selectedPhoto!.path),
        );
        _photoUrl = await PrivatePetStorage.signedUrl(_photoStoragePath!);
      }
      await AnnouncementRepository()
          .updateBreedingAnnouncement(BreedingAnnouncement(
            id: widget.item.id,
            ownerName: widget.item.ownerName,
            phone: _phone.text.trim().isEmpty
                ? widget.item.phone
                : _phone.text.trim(),
            breed: _breed.text.trim().isEmpty
                ? widget.item.breed
                : _breed.text.trim(),
            myDogName: _dogName.text.trim().isEmpty
                ? widget.item.myDogName
                : _dogName.text.trim(),
            myDogGender: widget.item.myDogGender,
            myDogAge: widget.item.myDogAge,
            myDogPhotoUrl: _photoUrl,
            photoStoragePath: _photoStoragePath,
            petAvatarUrl: widget.item.petAvatarUrl,
            petAvatarStoragePath: widget.item.petAvatarStoragePath,
            desiredBreed: widget.item.desiredBreed,
            conditions: _conditions.text.trim().isEmpty
                ? null
                : _conditions.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            location:
                _location.text.trim().isEmpty ? null : _location.text.trim(),
            createdAt: widget.item.createdAt,
            isActive: widget.item.isActive,
            ownerId: widget.item.ownerId,
            petId: widget.item.petId,
          ))
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не вдалося зберегти зміни. Перевірте інтернет і спробуйте ще раз.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Редагувати оголошення',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnnouncementPhotoEditor(
            photoUrl: _photoUrl,
            selectedPhoto: _selectedPhoto,
            onPick: _isSaving ? null : _pickPhoto,
          ),
          const SizedBox(height: 16),
          _EditField(label: 'Порода', controller: _breed),
          const SizedBox(height: 12),
          _EditField(label: 'Ім\'я собаки', controller: _dogName),
          const SizedBox(height: 12),
          _EditField(
              label: 'Умови в\'язки', controller: _conditions, maxLines: 3),
          const SizedBox(height: 12),
          _EditField(
              label: 'Телефон',
              controller: _phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          CityAutocompleteField(controller: _location, filled: true),
          const SizedBox(height: 12),
          _EditField(label: 'Примітки', controller: _notes, maxLines: 4),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Зберегти'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              widget.onToggle();
              Navigator.of(context).pop();
            },
            icon: Icon(widget.item.isActive
                ? Icons.archive_outlined
                : Icons.unarchive_outlined),
            label: Text(widget.item.isActive ? 'В архів' : 'Відновити'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AnnouncementPhotoEditor extends StatelessWidget {
  const _AnnouncementPhotoEditor({
    required this.photoUrl,
    required this.selectedPhoto,
    required this.onPick,
  });

  final String? photoUrl;
  final XFile? selectedPhoto;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: selectedPhoto != null
                    ? Image.file(
                        File(selectedPhoto!.path),
                        fit: BoxFit.cover,
                      )
                    : photoUrl?.isNotEmpty == true
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _PhotoPlaceholder(),
                          )
                        : const _PhotoPlaceholder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Замінити велике фото'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.pets,
          color: AppTheme.primary,
          size: 56,
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField(
      {required this.label,
      required this.controller,
      this.maxLines = 1,
      this.keyboardType});
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.surface,
      ),
    );
  }
}

// ─── Breed Filter ─────────────────────────────────────────────────────────────

class _BreedFilter extends StatelessWidget {
  const _BreedFilter(
      {required this.breeds,
      required this.selected,
      required this.onChanged,
      this.allLabel = 'Всі'});

  final List<String> breeds;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _Chip(
              label: allLabel,
              selected: selected == null,
              onTap: () => onChanged(null)),
          ...breeds.map((b) => _Chip(
                label: b,
                selected: selected == b,
                onTap: () => onChanged(selected == b ? null : b),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 32),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Breeding Card ────────────────────────────────────────────────────────────

class _BreedingCard extends StatelessWidget {
  const _BreedingCard({required this.item, required this.onTap});
  final BreedingAnnouncement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CompactAnnouncementPhoto(
                    photoUrl: item.petAvatarUrl,
                    fallbackIcon: Icons.favorite_outlined,
                    fallbackColor: AppTheme.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.breed,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(
                            '${item.myDogName} · ${item.genderLabel} · ${item.ageLabel}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                ],
              ),
              if (item.conditions != null) ...[
                const SizedBox(height: 10),
                Text(item.conditions!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(item.location ?? 'Не вказано',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text(_daysAgo(item.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sale Card ────────────────────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.item, required this.onTap});
  final SaleAnnouncement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CompactAnnouncementPhoto(
                    photoUrl: item.petAvatarUrl,
                    fallbackIcon: Icons.pets,
                    fallbackColor: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.breed,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(
                            '${item.genderLabel} · ${item.ageLabel} · ${item.color ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(item.priceLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Badge(
                    icon: Icons.vaccines_outlined,
                    label: 'Щеплення',
                    active: item.hasVaccinations ?? false,
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    icon: Icons.description_outlined,
                    label: 'Родовід',
                    active: item.hasPedigree ?? false,
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    icon: Icons.memory_outlined,
                    label: 'Чип',
                    active: item.hasChip ?? false,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(item.location ?? 'Не вказано',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text(_daysAgo(item.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactAnnouncementPhoto extends StatelessWidget {
  const _CompactAnnouncementPhoto({
    required this.photoUrl,
    required this.fallbackIcon,
    required this.fallbackColor,
  });

  final String? photoUrl;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 44,
        child: photoUrl?.isNotEmpty == true
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => ColoredBox(
        color: fallbackColor.withValues(alpha: 0.12),
        child: Icon(fallbackIcon, color: fallbackColor, size: 24),
      );
}

class _SquareAnnouncementPhoto extends StatelessWidget {
  const _SquareAnnouncementPhoto({
    required this.photoUrl,
    required this.fallbackIcon,
    required this.fallbackColor,
  });

  final String? photoUrl;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: photoUrl?.isNotEmpty == true
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => ColoredBox(
        color: fallbackColor.withValues(alpha: 0.12),
        child: Icon(fallbackIcon, color: fallbackColor, size: 52),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.success : AppTheme.border;
    final textColor = active ? AppTheme.success : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}

// ─── Breeding Detail ──────────────────────────────────────────────────────────

class _BreedingDetailScreen extends StatelessWidget {
  const _BreedingDetailScreen({required this.item});
  final BreedingAnnouncement item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(item.breed,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SquareAnnouncementPhoto(
            photoUrl: item.myDogPhotoUrl,
            fallbackIcon: Icons.favorite_outlined,
            fallbackColor: AppTheme.accent,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: item.petAvatarUrl?.isNotEmpty == true
                            ? Image.network(item.petAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.favorite_outlined,
                                    color: AppTheme.accent,
                                    size: 28))
                            : const Icon(Icons.favorite_outlined,
                                color: AppTheme.accent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.myDogName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 18)),
                            Text(
                                '${item.breed} · ${item.genderLabel} · ${item.ageLabel}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DetailSection(title: 'Про в\'язку', children: [
            if (item.desiredBreed != null)
              _DetailRow(
                  icon: Icons.pets_outlined,
                  label: 'Бажана порода',
                  value: item.desiredBreed!),
            if (item.conditions != null)
              _DetailRow(
                  icon: Icons.handshake_outlined,
                  label: 'Умови',
                  value: item.conditions!),
            if (item.location != null)
              _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Місто',
                  value: item.location!),
          ]),
          if (item.notes != null) ...[
            const SizedBox(height: 12),
            _DetailSection(title: 'Додатково', children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(item.notes!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          _DetailSection(title: 'Контакти', children: [
            _DetailRow(
                icon: Icons.person_outline,
                label: 'Ім\'я',
                value: item.ownerName),
            _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Телефон',
                value: item.phone),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: item.phone)),
            icon: const Icon(Icons.phone),
            label: Text('Зателефонувати: ${item.phone}'),
          ),
          if (item.ownerId != AnnouncementRepository().currentUserId)
            _SafetyActions(
              announcementId: item.id,
              ownerId: item.ownerId,
            ),
        ],
      ),
    );
  }
}

// ─── Sale Detail ──────────────────────────────────────────────────────────────

class _SaleDetailScreen extends StatelessWidget {
  const _SaleDetailScreen({required this.item});
  final SaleAnnouncement item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(item.breed,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SquareAnnouncementPhoto(
            photoUrl: item.photoUrl,
            fallbackIcon: Icons.pets,
            fallbackColor: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.petAvatarUrl?.isNotEmpty == true
                        ? Image.network(item.petAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.pets,
                                color: AppTheme.primary, size: 28))
                        : const Icon(Icons.pets,
                            color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.breed,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18)),
                        Text('${item.genderLabel} · ${item.ageLabel}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(item.priceLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppTheme.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DetailSection(title: 'Характеристики', children: [
            if (item.color != null)
              _DetailRow(
                  icon: Icons.palette_outlined,
                  label: 'Забарвлення',
                  value: item.color!),
            _DetailRow(
                icon: Icons.cake_outlined,
                label: 'Дата народження',
                value:
                    '${item.birthDate.day}.${item.birthDate.month}.${item.birthDate.year}'),
            if (item.location != null)
              _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Місто',
                  value: item.location!),
          ]),
          const SizedBox(height: 12),
          _DetailSection(title: 'Документи та здоров\'я', children: [
            _DetailRow(
                icon: Icons.vaccines_outlined,
                label: 'Щеплення',
                value: (item.hasVaccinations ?? false) ? 'Є' : 'Немає'),
            _DetailRow(
                icon: Icons.description_outlined,
                label: 'Родовід',
                value: (item.hasPedigree ?? false) ? 'Є' : 'Немає'),
            _DetailRow(
                icon: Icons.memory_outlined,
                label: 'Мікрочіп',
                value: (item.hasChip ?? false) ? 'Є' : 'Немає'),
          ]),
          if (item.notes != null) ...[
            const SizedBox(height: 12),
            _DetailSection(title: 'Про цуценя', children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(item.notes!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          _DetailSection(title: 'Контакти', children: [
            _DetailRow(
                icon: Icons.person_outline,
                label: 'Продавець',
                value: item.ownerName),
            _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Телефон',
                value: item.phone),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: item.phone)),
            icon: const Icon(Icons.phone),
            label: Text('Зателефонувати: ${item.phone}'),
          ),
          if (item.ownerId != AnnouncementRepository().currentUserId)
            _SafetyActions(
              announcementId: item.id,
              ownerId: item.ownerId,
            ),
        ],
      ),
    );
  }
}

// ─── Shared Detail Widgets ────────────────────────────────────────────────────

class _SafetyActions extends StatefulWidget {
  const _SafetyActions({required this.announcementId, required this.ownerId});

  final String announcementId;
  final String? ownerId;

  @override
  State<_SafetyActions> createState() => _SafetyActionsState();
}

class _SafetyActionsState extends State<_SafetyActions> {
  final _repository = AnnouncementRepository();
  bool _busy = false;

  Future<void> _report() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поскаржитися на оголошення?'),
        content: const Text(
          'Модератори перевірять оголошення. Не використовуйте скаргу для особистих суперечок.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Надіслати')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _repository.reportAnnouncement(widget.announcementId),
        success: 'Скаргу надіслано на перевірку.');
  }

  Future<void> _block() async {
    if (widget.ownerId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокувати користувача?'),
        content: const Text('Ви більше не бачитимете його оголошення.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Заблокувати')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _repository.blockOwner(widget.ownerId!),
        success: 'Користувача заблоковано.');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _run(Future<void> Function() operation,
      {required String success}) async {
    setState(() => _busy = true);
    try {
      await operation();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Не вдалося виконати дію. Спробуйте ще раз.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _report,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Поскаржитися'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy || widget.ownerId == null ? null : _block,
              icon: const Icon(Icons.block_outlined),
              label: const Text('Заблокувати'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

String _daysAgo(DateTime date) {
  final diff = DateTime.now().difference(date).inDays;
  if (diff == 0) return 'Сьогодні';
  if (diff == 1) return 'Вчора';
  return '$diff дн. тому';
}
