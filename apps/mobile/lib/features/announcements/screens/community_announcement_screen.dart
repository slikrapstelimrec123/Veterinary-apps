import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/announcement_media_storage.dart';
import '../data/announcement_repository.dart';
import '../domain/community_announcement.dart';

class CommunityAnnouncementTab extends StatefulWidget {
  const CommunityAnnouncementTab({
    super.key,
    required this.type,
  });

  final CommunityAnnouncementType type;

  @override
  State<CommunityAnnouncementTab> createState() =>
      _CommunityAnnouncementTabState();
}

class _CommunityAnnouncementTabState extends State<CommunityAnnouncementTab> {
  final _repository = AnnouncementRepository();
  final _scrollController = ScrollController();
  final List<CommunityAnnouncement> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant CommunityAnnouncementTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 320 &&
        !_loadingMore &&
        _hasMore) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 0;
        _hasMore = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final page = reset ? 0 : _page;
      final items = await _repository.getCommunityAnnouncements(
        widget.type,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(items.where(
          (item) => !_items.any((existing) => existing.id == item.id),
        ));
        _page = page + 1;
        _hasMore = items.length == 30;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не вдалося завантажити оголошення.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        text: _error!,
        actionLabel: 'Спробувати ще раз',
        onAction: () => _load(reset: true),
      );
    }
    if (_items.isEmpty) {
      return _MessageState(
        icon: _iconForType(widget.type),
        text: 'У цьому розділі ще немає оголошень.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[index];
          return CommunityAnnouncementCard(
            item: item,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommunityAnnouncementDetailScreen(item: item),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CommunityAnnouncementCard extends StatelessWidget {
  const CommunityAnnouncementCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final CommunityAnnouncement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item.type == CommunityAnnouncementType.event &&
        item.photoUrl?.isNotEmpty == true;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: hasPhoto
                      ? Image.network(
                          item.photoUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 168,
                          errorBuilder: (_, __, ___) => _TypeIcon(item.type),
                        )
                      : _TypeIcon(item.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityAnnouncementDetailScreen extends StatelessWidget {
  const CommunityAnnouncementDetailScreen({
    super.key,
    required this.item,
  });

  final CommunityAnnouncement item;

  Future<void> _openWebsite(BuildContext context) async {
    final raw = item.website?.trim();
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося відкрити сайт.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          item.type.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (item.type == CommunityAnnouncementType.event &&
              item.photoUrl?.isNotEmpty == true) ...[
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  item.photoUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 1200,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Адреса',
                    value: item.address,
                  ),
                  if (item.type == CommunityAnnouncementType.event)
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Дата проведення',
                      value: item.subtitle,
                    ),
                  if (item.serviceCategory != null)
                    _InfoRow(
                      icon: Icons.design_services_outlined,
                      label: 'Категорія',
                      value: item.serviceCategory!.label,
                    ),
                  if (item.priceAmount != null)
                    _InfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Ціна',
                      value: '${item.priceAmount} грн',
                    ),
                  if (item.offerText?.isNotEmpty == true)
                    _InfoRow(
                      icon: Icons.local_offer_outlined,
                      label: 'Пропозиція',
                      value: item.offerText!,
                    ),
                  if (item.validFrom != null)
                    _InfoRow(
                      icon: Icons.date_range_outlined,
                      label: 'Початок дії',
                      value: _formatDate(item.validFrom!),
                    ),
                  if (item.validUntil != null)
                    _InfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Діє до',
                      value: _formatDate(item.validUntil!),
                    ),
                  if (item.promoCode?.isNotEmpty == true)
                    _InfoRow(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Промокод',
                      value: item.promoCode!,
                    ),
                  if (item.contact?.isNotEmpty == true)
                    _InfoRow(
                      icon: Icons.contact_phone_outlined,
                      label: 'Контакти',
                      value: item.contact!,
                    ),
                ],
              ),
            ),
          ),
          if (item.website?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openWebsite(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Відкрити сайт'),
            ),
          ],
          if (item.ownerId != AnnouncementRepository().currentUserId) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await AnnouncementRepository().reportAnnouncement(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Скаргу надіслано на перевірку.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Поскаржитися'),
            ),
          ],
        ],
      ),
    );
  }
}

class CommunityAnnouncementFormScreen extends StatefulWidget {
  const CommunityAnnouncementFormScreen({
    super.key,
    required this.type,
    this.item,
  });

  final CommunityAnnouncementType type;
  final CommunityAnnouncement? item;

  @override
  State<CommunityAnnouncementFormScreen> createState() =>
      _CommunityAnnouncementFormScreenState();
}

class _CommunityAnnouncementFormScreenState
    extends State<CommunityAnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = AnnouncementRepository();
  final _imagePicker = ImagePicker();

  late final TextEditingController _title =
      TextEditingController(text: widget.item?.title ?? '');
  late final TextEditingController _address =
      TextEditingController(text: widget.item?.address ?? '');
  late final TextEditingController _contact =
      TextEditingController(text: widget.item?.contact ?? '');
  late final TextEditingController _price = TextEditingController(
    text: widget.item?.priceAmount?.toString() ?? '',
  );
  late final TextEditingController _website =
      TextEditingController(text: widget.item?.website ?? '');
  late final TextEditingController _offer =
      TextEditingController(text: widget.item?.offerText ?? '');
  late final TextEditingController _promoCode =
      TextEditingController(text: widget.item?.promoCode ?? '');

  DateTime? _eventDate;
  DateTime? _validFrom;
  DateTime? _validUntil;
  ServiceCategory _serviceCategory = ServiceCategory.dogTrainer;
  XFile? _selectedPhoto;
  String? _photoUrl;
  String? _photoStoragePath;
  bool _saving = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _eventDate = widget.item?.eventDate;
    _validFrom = widget.item?.validFrom ?? DateTime.now();
    _validUntil = widget.item?.validUntil;
    _serviceCategory =
        widget.item?.serviceCategory ?? ServiceCategory.dogTrainer;
    _photoUrl = widget.item?.photoUrl;
    _photoStoragePath = widget.item?.photoStoragePath;
  }

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _contact.dispose();
    _price.dispose();
    _website.dispose();
    _offer.dispose();
    _promoCode.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (image != null && mounted) setState(() => _selectedPhoto = image);
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (widget.type == CommunityAnnouncementType.event && _eventDate == null) {
      _showError('Оберіть дату проведення події.');
      return;
    }
    if (widget.type == CommunityAnnouncementType.event &&
        _selectedPhoto == null &&
        _photoStoragePath == null) {
      _showError('Додайте фото події.');
      return;
    }
    if (widget.type == CommunityAnnouncementType.offer && _validUntil == null) {
      _showError('Оберіть строк дії пропозиції.');
      return;
    }
    if (_validFrom != null &&
        _validUntil != null &&
        _validUntil!.isBefore(_validFrom!)) {
      _showError('Дата завершення не може бути раніше початку.');
      return;
    }

    setState(() => _saving = true);
    final id = widget.item?.id ?? _uuidV4();
    try {
      if (_selectedPhoto != null) {
        _photoStoragePath = await AnnouncementMediaStorage.uploadImage(
          announcementId: id,
          file: File(_selectedPhoto!.path),
        );
        _photoUrl = await AnnouncementMediaStorage.signedUrl(_photoStoragePath);
      }
      final item = CommunityAnnouncement(
        id: id,
        type: widget.type,
        title: _title.text.trim(),
        address: _address.text.trim(),
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        eventDate: _eventDate,
        contact: _emptyToNull(_contact.text),
        serviceCategory: widget.type == CommunityAnnouncementType.service
            ? _serviceCategory
            : null,
        priceAmount: widget.type == CommunityAnnouncementType.service
            ? int.tryParse(_price.text.trim())
            : null,
        website: _emptyToNull(_website.text),
        offerText: _emptyToNull(_offer.text),
        validFrom:
            widget.type == CommunityAnnouncementType.offer ? _validFrom : null,
        validUntil:
            widget.type == CommunityAnnouncementType.offer ? _validUntil : null,
        promoCode: _emptyToNull(_promoCode.text),
        photoUrl:
            widget.type == CommunityAnnouncementType.event ? _photoUrl : null,
        photoStoragePath: widget.type == CommunityAnnouncementType.event
            ? _photoStoragePath
            : null,
        isActive: widget.item?.isActive ?? true,
        ownerId: widget.item?.ownerId ?? _repository.currentUserId,
      );
      if (_editing) {
        await _repository.updateCommunityAnnouncement(item);
      } else {
        await _repository.addCommunityAnnouncement(item);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        _showError('Не вдалося зберегти оголошення. Спробуйте ще раз.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _editing ? 'Редагувати оголошення' : 'Нове оголошення',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.type == CommunityAnnouncementType.event) ...[
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _selectedPhoto != null
                      ? Image.file(
                          File(_selectedPhoto!.path),
                          fit: BoxFit.cover,
                        )
                      : _photoUrl?.isNotEmpty == true
                          ? Image.network(_photoUrl!, fit: BoxFit.cover)
                          : const _TypeIcon(
                              CommunityAnnouncementType.event,
                            ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _selectedPhoto == null && _photoUrl == null
                      ? 'Додати фото'
                      : 'Замінити фото',
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Назва *'),
              maxLength: 100,
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Адреса *',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 10),
            if (widget.type == CommunityAnnouncementType.event) ...[
              _DateField(
                label: 'Дата проведення *',
                value: _eventDate,
                onTap: () async {
                  final date = await _pickDate(_eventDate);
                  if (date != null) setState(() => _eventDate = date);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(
                  labelText: 'Контакти (необов’язково)',
                ),
              ),
            ],
            if (widget.type == CommunityAnnouncementType.service) ...[
              DropdownButtonFormField<ServiceCategory>(
                value: _serviceCategory,
                decoration: const InputDecoration(labelText: 'Тип послуги *'),
                items: ServiceCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _serviceCategory = value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Ціна, грн *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final price = int.tryParse(value?.trim() ?? '');
                  if (price == null || price < 0) {
                    return 'Вкажіть коректну ціну';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(labelText: 'Контакти *'),
                validator: _required,
              ),
            ],
            if (widget.type == CommunityAnnouncementType.offer) ...[
              TextFormField(
                controller: _website,
                decoration: const InputDecoration(labelText: 'Сайт *'),
                keyboardType: TextInputType.url,
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _offer,
                decoration: const InputDecoration(
                  labelText: 'Пропозиція *',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                validator: _required,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Початок дії',
                      value: _validFrom,
                      onTap: () async {
                        final date = await _pickDate(_validFrom);
                        if (date != null) setState(() => _validFrom = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateField(
                      label: 'Діє до *',
                      value: _validUntil,
                      onTap: () async {
                        final date = await _pickDate(_validUntil);
                        if (date != null) setState(() => _validUntil = date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _promoCode,
                decoration: const InputDecoration(
                  labelText: 'Промокод (необов’язково)',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.publish_outlined),
              label: Text(_editing ? 'Зберегти зміни' : 'Опублікувати'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Заповніть це поле' : null;
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Оберіть дату' : _formatDate(value!)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon(this.type);

  final CommunityAnnouncementType type;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.primary.withOpacity(0.1),
      child: Icon(_iconForType(type), color: AppTheme.primary, size: 28),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Повторити'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(CommunityAnnouncementType type) {
  return switch (type) {
    CommunityAnnouncementType.event => Icons.event_outlined,
    CommunityAnnouncementType.service => Icons.design_services_outlined,
    CommunityAnnouncementType.offer => Icons.local_offer_outlined,
  };
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
