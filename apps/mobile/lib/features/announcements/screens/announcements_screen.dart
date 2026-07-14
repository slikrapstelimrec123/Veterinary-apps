import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../data/announcement_repository.dart';
import '../domain/breeding_announcement.dart';
import '../domain/sale_announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Оголошення',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tab,
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
            Tab(text: 'В\'язка'),
            Tab(text: 'Продаж'),
            Tab(text: 'Мої'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _BreedingTab(),
          _SaleTab(),
          _MyAnnouncementsTab(),
        ],
      ),
    );
  }
}

// ─── Breeding Tab ─────────────────────────────────────────────────────────────

class _BreedingTab extends StatefulWidget {
  const _BreedingTab();

  @override
  State<_BreedingTab> createState() => _BreedingTabState();
}

class _BreedingTabState extends State<_BreedingTab> {
  final _repo = AnnouncementRepository();
  late Future<List<BreedingAnnouncement>> _future;
  String? _selectedBreed;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
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
    final breeds = _repo.getBreedingBreeds();
    final cities = _repo.getBreedingCities();

    return Column(
      children: [
        _BreedFilter(
          breeds: breeds,
          selected: _selectedBreed,
          onChanged: (b) {
            setState(() => _selectedBreed = b);
            _load();
          },
        ),
        _BreedFilter(
          breeds: cities,
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
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _BreedingDetailScreen(item: items[i]),
                  )),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Sale Tab ─────────────────────────────────────────────────────────────────

class _SaleTab extends StatefulWidget {
  const _SaleTab();

  @override
  State<_SaleTab> createState() => _SaleTabState();
}

class _SaleTabState extends State<_SaleTab> {
  final _repo = AnnouncementRepository();
  late Future<List<SaleAnnouncement>> _future;
  String? _selectedBreed;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
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
    final breeds = _repo.getSaleBreeds();
    final cities = _repo.getSaleCities();

    return Column(
      children: [
        _BreedFilter(
          breeds: breeds,
          selected: _selectedBreed,
          onChanged: (b) {
            setState(() => _selectedBreed = b);
            _load();
          },
        ),
        _BreedFilter(
          breeds: cities,
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
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _SaleDetailScreen(item: items[i]),
                  )),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── My Announcements Tab ─────────────────────────────────────────────────────

class _MyAnnouncementsTab extends StatefulWidget {
  const _MyAnnouncementsTab();

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
                  active: true,
                  onToggle: () => setState(() {})),
              _MyAnnouncementsList(
                  saleFuture: _mySale(false),
                  breedingFuture: _myBreeding(false),
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
    required this.active,
    required this.onToggle,
  });

  final Future<List<SaleAnnouncement>> saleFuture;
  final Future<List<BreedingAnnouncement>> breedingFuture;
  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([saleFuture, breedingFuture]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = (snap.data?[0] as List<SaleAnnouncement>?) ?? [];
        final breedings = (snap.data?[1] as List<BreedingAnnouncement>?) ?? [];

        if (sales.isEmpty && breedings.isEmpty) {
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
                child: Text('Продаж',
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
                      icon: Icons.pets,
                      onToggle: () async {
                        await AnnouncementRepository().toggleSaleActive(s.id);
                        onToggle();
                      },
                      onDelete: () async {
                        await AnnouncementRepository().deleteSaleAnnouncement(s.id);
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
                          .then((_) => onToggle()),
                    ),
                  )),
            ],
            if (breedings.isNotEmpty) ...[
              Padding(
                padding:
                    EdgeInsets.only(top: sales.isNotEmpty ? 8 : 0, bottom: 8),
                child: const Text('В\'язка',
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
                      icon: Icons.favorite_outlined,
                      onToggle: () async {
                        await AnnouncementRepository().toggleBreedingActive(b.id);
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
                          .then((_) => onToggle()),
                    ),
                  )),
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
    required this.icon,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final String? location;
  final DateTime createdAt;
  final bool active;
  final IconData icon;
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
              child: Icon(icon,
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
  late final TextEditingController _notes =
      TextEditingController(text: widget.item.notes ?? '');

  @override
  void dispose() {
    _breed.dispose();
    _name.dispose();
    _price.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_price.text.trim()) ?? widget.item.price;
    await AnnouncementRepository().updateSaleAnnouncement(
      SaleAnnouncement(
        id: widget.item.id,
        ownerName: widget.item.ownerName,
        phone: widget.item.phone,
        breed:
            _breed.text.trim().isEmpty ? widget.item.breed : _breed.text.trim(),
        puppyName:
            _name.text.trim().isEmpty ? widget.item.puppyName : _name.text.trim(),
        gender: widget.item.gender,
        birthDate: widget.item.birthDate,
        price: price,
        photoUrl: widget.item.photoUrl,
        color: widget.item.color,
        hasVaccinations: widget.item.hasVaccinations,
        hasPedigree: widget.item.hasPedigree,
        hasChip: widget.item.hasChip,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        createdAt: widget.item.createdAt,
        isActive: widget.item.isActive,
        ownerId: widget.item.ownerId,
        petId: widget.item.petId,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Редагувати оголошення',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EditField(label: 'Порода', controller: _breed),
          const SizedBox(height: 12),
          _EditField(label: 'Ім\'я цуценяти', controller: _name),
          const SizedBox(height: 12),
          _EditField(
              label: 'Ціна (грн)',
              controller: _price,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          CityAutocompleteField(controller: _location, filled: true),
          const SizedBox(height: 12),
          _EditField(label: 'Примітки', controller: _notes, maxLines: 4),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Зберегти')),
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
  late final TextEditingController _notes =
      TextEditingController(text: widget.item.notes ?? '');

  @override
  void dispose() {
    _breed.dispose();
    _dogName.dispose();
    _conditions.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await AnnouncementRepository().updateBreedingAnnouncement(BreedingAnnouncement(
      id: widget.item.id,
      ownerName: widget.item.ownerName,
      phone: widget.item.phone,
      breed:
          _breed.text.trim().isEmpty ? widget.item.breed : _breed.text.trim(),
      myDogName: _dogName.text.trim().isEmpty
          ? widget.item.myDogName
          : _dogName.text.trim(),
      myDogGender: widget.item.myDogGender,
      myDogAge: widget.item.myDogAge,
      myDogPhotoUrl: widget.item.myDogPhotoUrl,
      desiredBreed: widget.item.desiredBreed,
      conditions:
          _conditions.text.trim().isEmpty ? null : _conditions.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      createdAt: widget.item.createdAt,
      isActive: widget.item.isActive,
      ownerId: widget.item.ownerId,
      petId: widget.item.petId,
    ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Редагувати оголошення',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EditField(label: 'Порода', controller: _breed),
          const SizedBox(height: 12),
          _EditField(label: 'Ім\'я собаки', controller: _dogName),
          const SizedBox(height: 12),
          _EditField(
              label: 'Умови в\'язки', controller: _conditions, maxLines: 3),
          const SizedBox(height: 12),
          CityAutocompleteField(controller: _location, filled: true),
          const SizedBox(height: 12),
          _EditField(label: 'Примітки', controller: _notes, maxLines: 4),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Зберегти')),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.myDogPhotoUrl != null
                        ? Image.network(item.myDogPhotoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _AnnouncementAvatar(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                icon: Icons.favorite_outlined,
                                iconColor: AppTheme.accent))
                        : _AnnouncementAvatar(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            icon: Icons.favorite_outlined,
                            iconColor: AppTheme.accent),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.photoUrl != null
                        ? Image.network(item.photoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _AnnouncementAvatar(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                icon: Icons.pets,
                                iconColor: AppTheme.primary))
                        : _AnnouncementAvatar(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            icon: Icons.pets,
                            iconColor: AppTheme.primary),
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

class _AnnouncementAvatar extends StatelessWidget {
  const _AnnouncementAvatar(
      {required this.color, required this.icon, required this.iconColor});
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: color,
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(item.breed,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                        child: const Icon(Icons.favorite_outlined,
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(item.breed,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    child: const Icon(Icons.pets,
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Надіслати')),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Заблокувати')),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не вдалося виконати дію: $error')),
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
