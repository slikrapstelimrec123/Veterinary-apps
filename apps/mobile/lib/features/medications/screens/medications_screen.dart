import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../data/medication_repository.dart';
import '../domain/pet_medication.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key, required this.petId, required this.petName});

  final String petId;
  final String petName;

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _repo = MedicationRepository();
  late Future<List<PetMedication>> _future = _repo.getMedications(widget.petId);

  void _refresh() => setState(() => _future = _repo.getMedications(widget.petId));

  Future<void> _add() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddMedicationScreen(petId: widget.petId, petName: widget.petName),
    ));
    if (result != null) _refresh();
  }

  Future<void> _delete(PetMedication med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити запис?'),
        content: Text('Видалити "${med.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Видалити', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteMedication(med.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PetMedication>>(
      future: _future,
      builder: (context, snapshot) {
        final meds = snapshot.data ?? [];
        return AppScaffold(
          title: 'Препарати та лікування',
          subtitle: widget.petName,
          actions: [IconButton(icon: const Icon(Icons.add), tooltip: 'Додати', onPressed: _add)],
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              ErrorState(message: 'Не вдалося завантажити дані.', onRetry: _refresh)
            else if (meds.isEmpty)
              EmptyState(
                title: 'Записів про препарати немає',
                message: 'Додайте перший запис — від кліщів, дегельмінтизацію або будь-які інші препарати.',
                icon: Icons.medication_outlined,
                action: FilledButton(onPressed: _add, child: const Text('Додати препарат')),
              )
            else ...[
              // Show upcoming/overdue reminders first
              ..._buildReminders(meds, context),
              ...meds.map((m) => _MedicationCard(med: m, onDelete: () => _delete(m))),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Додати препарат'),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildReminders(List<PetMedication> meds, BuildContext context) {
    final upcoming = meds.where((m) => m.nextDoseDate != null && (m.nextDueSoon || m.nextDoseOverdue)).toList();
    if (upcoming.isEmpty) return [];

    return [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.notifications_active_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text('Нагадування', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
              ]),
              const SizedBox(height: 8),
              ...upcoming.map((m) {
                final overdue = m.nextDoseOverdue;
                final label = overdue
                    ? 'Протерміновано: ${m.name}'
                    : 'Незабаром: ${m.name} — ${_formatDate(m.nextDoseDate!)}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Icon(overdue ? Icons.warning_amber_outlined : Icons.schedule_outlined, size: 16,
                        color: overdue ? AppTheme.danger : AppTheme.warning),
                    const SizedBox(width: 6),
                    Expanded(child: Text(label, style: TextStyle(color: overdue ? AppTheme.danger : AppTheme.textMain))),
                  ]),
                );
              }),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.med, required this.onDelete});
  final PetMedication med;
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
                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(med.categoryLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.calendar_today_outlined, label: 'Дата прийому', value: _formatDate(med.givenDate)),
              if (med.dosage != null)
                _InfoRow(icon: Icons.scale_outlined, label: 'Дозування', value: med.dosage!),
              if (med.nextDoseDate != null)
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Наступний прийом',
                  value: _formatDate(med.nextDoseDate!),
                  valueColor: med.nextDoseOverdue ? AppTheme.danger : med.nextDueSoon ? AppTheme.warning : null,
                ),
              if (med.notes != null && med.notes!.isNotEmpty)
                _InfoRow(icon: Icons.notes_outlined, label: 'Нотатки', value: med.notes!),
              if (med.reminderEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.notifications_active_outlined, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    const Text('Нагадування увімкнено', style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor)),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

// ─── Add form ────────────────────────────────────────────────────────────────

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key, required this.petId, required this.petName});

  final String petId;
  final String petName;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'tick_flea';
  DateTime _givenDate = DateTime.now();
  DateTime? _nextDoseDate;
  bool _reminderEnabled = false;
  bool _saving = false;

  static const _categories = [
    ('tick_flea', 'Від кліщів / бліх'),
    ('deworming', 'Дегельмінтизація'),
    ('vitamin', 'Вітаміни / добавки'),
    ('antibiotic', 'Антибіотик'),
    ('other', 'Інше'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickGivenDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _givenDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _givenDate = picked);
  }

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDoseDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _nextDoseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final med = PetMedication(
        id: '',
        petId: widget.petId,
        name: _nameController.text.trim(),
        givenDate: _givenDate,
        dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
        category: _category,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        nextDoseDate: _nextDoseDate,
        reminderEnabled: _reminderEnabled,
      );

      await MedicationRepository().addMedication(med);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запис про препарат збережено.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося зберегти. Спробуйте ще раз.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Додати препарат'),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _save, child: const Text('Зберегти')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Label('Основна інформація'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Назва препарату *',
                        border: InputBorder.none,
                        hintText: 'напр. Bravecto, Milbemax...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Вкажіть назву' : null,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Дозування (необов\'язково)',
                        border: InputBorder.none,
                        hintText: 'напр. 1 таблетка, 0.5 мл...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Категорія'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'other'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Дати'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Дата прийому *'),
                      subtitle: Text(_formatDate(_givenDate)),
                      onTap: _pickGivenDate,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Наступний прийом'),
                      subtitle: Text(_nextDoseDate != null ? _formatDate(_nextDoseDate!) : 'Не вказано'),
                      onTap: _pickNextDate,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    if (_nextDoseDate != null) ...[
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined),
                        title: const Text('Нагадування'),
                        subtitle: const Text('Сповістити перед наступним прийомом'),
                        value: _reminderEnabled,
                        onChanged: (v) => setState(() => _reminderEnabled = v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Нотатки'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Нотатки (необов\'язково)',
                    border: InputBorder.none,
                    hintText: 'реакція на препарат, особливості...',
                  ),
                  maxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Зберегти запис')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.titleMedium);
}
