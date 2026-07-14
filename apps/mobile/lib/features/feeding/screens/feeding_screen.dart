import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/feeding_repository.dart';
import '../domain/pet_feeding.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key, required this.petId, required this.petName});
  final String petId;
  final String petName;

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  final _repo = FeedingRepository();
  List<PetFeeding>? _feedings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(showLoading: false);
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _repo.getFeedings(widget.petId);
      if (mounted) {
        setState(() {
          _feedings = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    final result =
        await Navigator.of(context).push<PetFeeding>(MaterialPageRoute(
      builder: (_) => AddFeedingScreen(petId: widget.petId),
    ));
    if (result != null && mounted) {
      setState(() => _feedings = [result, ...?_feedings]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запис про харчування збережено.')),
      );
    }
  }

  Future<void> _edit(PetFeeding feeding) async {
    final result =
        await Navigator.of(context).push<PetFeeding>(MaterialPageRoute(
      builder: (_) => EditFeedingScreen(feeding: feeding),
    ));
    if (result != null && mounted) {
      setState(() => _feedings =
          _feedings?.map((f) => f.id == result.id ? result : f).toList());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запис оновлено.')),
      );
    }
  }

  Future<void> _delete(PetFeeding feeding) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити запис?'),
        content: Text('Видалити "${feeding.foodName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Видалити',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() =>
          _feedings = _feedings?.where((f) => f.id != feeding.id).toList());
      try {
        await _repo.deleteFeeding(feeding.id);
      } catch (_) {
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _feedings?.where((f) => f.isCurrent).toList() ?? [];
    final history = _feedings?.where((f) => !f.isCurrent).toList() ?? [];

    return AppScaffold(
      title: 'Харчування',
      subtitle: widget.petName,
      actions: [
        IconButton(
            icon: const Icon(Icons.add), tooltip: 'Додати', onPressed: _add),
      ],
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          ErrorState(message: 'Не вдалося завантажити дані.', onRetry: _load)
        else if ((_feedings ?? []).isEmpty)
          EmptyState(
            title: 'Записів немає',
            message:
                'Додайте поточний корм та ведіть історію харчування вашого улюбленця.',
            icon: Icons.restaurant_outlined,
            action:
                FilledButton(onPressed: _add, child: const Text('Додати корм')),
          )
        else ...[
          if (current.isNotEmpty) ...[
            const _SectionLabel('Поточний корм'),
            const SizedBox(height: 8),
            ...current.map((f) => _FeedingCard(
                feeding: f,
                onEdit: () => _edit(f),
                onDelete: () => _delete(f))),
            const SizedBox(height: 16),
          ],
          if (history.isNotEmpty) ...[
            const _SectionLabel('Історія харчування'),
            const SizedBox(height: 8),
            ...history.map((f) => _FeedingCard(
                feeding: f,
                onEdit: () => _edit(f),
                onDelete: () => _delete(f))),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Додати корм'),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _FeedingCard extends StatelessWidget {
  const _FeedingCard(
      {required this.feeding, required this.onEdit, required this.onDelete});
  final PetFeeding feeding;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(feeding.foodName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                            if (feeding.isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Зараз',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        if (feeding.brand != null)
                          Text(feeding.brand!,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (feeding.foodType != null)
                _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Тип',
                    value: feeding.foodTypeLabel),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'З',
                value: _fmt(feeding.startDate),
              ),
              if (feeding.endDate != null)
                _InfoRow(
                    icon: Icons.event_outlined,
                    label: 'По',
                    value: _fmt(feeding.endDate!)),
              if (feeding.rating != null)
                _InfoRow(
                  icon: Icons.star_outline,
                  label: 'Оцінка',
                  value:
                      '${'★' * feeding.rating!}${'☆' * (5 - feeding.rating!)}',
                ),
              if (feeding.notes != null && feeding.notes!.isNotEmpty)
                _InfoRow(
                    icon: Icons.notes_outlined,
                    label: 'Нотатки',
                    value: feeding.notes!),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

// ─── Add / Edit forms ─────────────────────────────────────────────────────────

class AddFeedingScreen extends StatefulWidget {
  const AddFeedingScreen({super.key, required this.petId});
  final String petId;

  @override
  State<AddFeedingScreen> createState() => _AddFeedingScreenState();
}

class _AddFeedingScreenState extends State<AddFeedingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();

  String _foodType = 'dry';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _rating;
  bool _saving = false;

  static const _types = [
    ('dry', 'Сухий корм'),
    ('wet', 'Вологий корм'),
    ('raw', 'Натуральне харчування'),
    ('mixed', 'Змішане'),
    ('prescription', 'Лікувальний корм'),
    ('other', 'Інше'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final feeding = PetFeeding(
        id: '',
        petId: widget.petId,
        foodName: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        foodType: _foodType,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        rating: _rating,
      );

      final saved = await FeedingRepository().addFeeding(feeding);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Не вдалося зберегти. Спробуйте ще раз.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FeedingForm(
        title: 'Додати корм',
        formKey: _formKey,
        nameController: _nameController,
        brandController: _brandController,
        notesController: _notesController,
        foodType: _foodType,
        startDate: _startDate,
        endDate: _endDate,
        rating: _rating,
        saving: _saving,
        types: _types,
        onTypeChanged: (v) => setState(() => _foodType = v),
        onPickStart: _pickStart,
        onPickEnd: _pickEnd,
        onClearEnd: () => setState(() => _endDate = null),
        onRatingChanged: (v) => setState(() => _rating = v),
        onSave: _save,
      );
}

class EditFeedingScreen extends StatefulWidget {
  const EditFeedingScreen({super.key, required this.feeding});
  final PetFeeding feeding;

  @override
  State<EditFeedingScreen> createState() => _EditFeedingScreenState();
}

class _EditFeedingScreenState extends State<EditFeedingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.feeding.foodName);
  late final _brandController =
      TextEditingController(text: widget.feeding.brand ?? '');
  late final _notesController =
      TextEditingController(text: widget.feeding.notes ?? '');

  late String _foodType = widget.feeding.foodType ?? 'dry';
  late DateTime _startDate = widget.feeding.startDate;
  late DateTime? _endDate = widget.feeding.endDate;
  late int? _rating = widget.feeding.rating;
  bool _saving = false;

  static const _types = [
    ('dry', 'Сухий корм'),
    ('wet', 'Вологий корм'),
    ('raw', 'Натуральне харчування'),
    ('mixed', 'Змішане'),
    ('prescription', 'Лікувальний корм'),
    ('other', 'Інше'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updated = PetFeeding(
        id: widget.feeding.id,
        petId: widget.feeding.petId,
        foodName: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        foodType: _foodType,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        rating: _rating,
        createdAt: widget.feeding.createdAt,
      );

      final saved = await FeedingRepository().updateFeeding(updated);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Не вдалося зберегти. Спробуйте ще раз.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FeedingForm(
        title: 'Редагувати корм',
        formKey: _formKey,
        nameController: _nameController,
        brandController: _brandController,
        notesController: _notesController,
        foodType: _foodType,
        startDate: _startDate,
        endDate: _endDate,
        rating: _rating,
        saving: _saving,
        types: _types,
        onTypeChanged: (v) => setState(() => _foodType = v),
        onPickStart: _pickStart,
        onPickEnd: _pickEnd,
        onClearEnd: () => setState(() => _endDate = null),
        onRatingChanged: (v) => setState(() => _rating = v),
        onSave: _save,
      );
}

class _FeedingForm extends StatelessWidget {
  const _FeedingForm({
    required this.title,
    required this.formKey,
    required this.nameController,
    required this.brandController,
    required this.notesController,
    required this.foodType,
    required this.startDate,
    required this.endDate,
    required this.rating,
    required this.saving,
    required this.types,
    required this.onTypeChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearEnd,
    required this.onRatingChanged,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController brandController;
  final TextEditingController notesController;
  final String foodType;
  final DateTime startDate;
  final DateTime? endDate;
  final int? rating;
  final bool saving;
  final List<(String, String)> types;
  final void Function(String) onTypeChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearEnd;
  final void Function(int?) onRatingChanged;
  final VoidCallback onSave;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (saving)
            const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: onSave, child: const Text('Зберегти')),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Основна інформація',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Назва корму *',
                        border: InputBorder.none,
                        hintText: 'напр. Royal Canin Adult, Acana...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Вкажіть назву'
                          : null,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: brandController,
                      decoration: const InputDecoration(
                        labelText: 'Виробник (необов\'язково)',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Тип харчування',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  initialValue: foodType,
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: types
                      .map((t) =>
                          DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                      .toList(),
                  onChanged: (v) => onTypeChanged(v ?? 'dry'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Дати', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Дата початку *'),
                      subtitle: Text(_fmt(startDate)),
                      onTap: onPickStart,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Дата закінчення'),
                      subtitle: Text(endDate != null
                          ? _fmt(endDate!)
                          : 'Не вказано (поточний корм)'),
                      onTap: onPickEnd,
                      trailing: endDate != null
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: onClearEnd,
                            )
                          : const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Оцінка корму',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      icon: Icon(
                        star <= (rating ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: star <= (rating ?? 0)
                            ? Colors.amber
                            : AppTheme.textSecondary,
                        size: 36,
                      ),
                      onPressed: () =>
                          onRatingChanged(rating == star ? null : star),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Нотатки', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Як впливає на тварину (необов\'язково)',
                    border: InputBorder.none,
                    hintText: 'реакція, апетит, шерсть, травлення...',
                  ),
                  maxLines: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: saving ? null : onSave,
                child: const Text('Зберегти')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
